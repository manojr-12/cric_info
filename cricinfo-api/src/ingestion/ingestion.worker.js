import { chromium } from 'playwright';
import { extractMatch, getMatchUrl, normalizeMessageId } from '../utils/match.utils.js';

const DISCOVERY_URL = 'https://www.espncricinfo.com/live-cricket-score';

const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

const isTransientNetworkError = (err) => {
  const msg = String(err?.message || '');
  return (
    msg.includes('ERR_NETWORK_CHANGED') ||
    msg.includes('ERR_INTERNET_DISCONNECTED') ||
    msg.includes('ERR_NAME_NOT_RESOLVED') ||
    msg.includes('ERR_TIMED_OUT') ||
    msg.includes('Timeout') ||
    msg.includes('Navigation timeout') ||
    msg.includes('Invalid matches payload')
  );
};

const isMatchFinishedPayload = (payload) => {
  const status = String(payload?.match?.status || '').toUpperCase();
  const state = String(payload?.match?.state || '').toUpperCase();
  return status === 'RESULT' || state === 'POST';
};

const isBodyUnavailableError = (err) => {
  const msg = String(err?.message || '');
  return msg.includes('No data found for resource with given identifier');
};

const isNonJsonBodyError = (err) => {
  const msg = String(err?.message || '');
  return msg.includes('Unexpected token');
};

const tryReadJson = async (response) => {
  const headers = response.headers();
  const contentType = String(headers['content-type'] || '');

  if (contentType && !contentType.includes('application/json')) {
    return null;
  }

  try {
    return await response.json();
  } catch (err) {
    if (isBodyUnavailableError(err) || isNonJsonBodyError(err)) {
      return null;
    }

    throw err;
  }
};

export class IngestionWorker {
  constructor({ scoresRepo, mappingRepo }) {
    this.scoresRepo = scoresRepo;
    this.mappingRepo = mappingRepo;
    this.browser = null;
    this.discoveryContext = null;
    this.discoveryPage = null;
    this.watchers = new Map();
  }

  async init() {
    if (this.browser) {
      return;
    }

    this.browser = await chromium.launch({
      headless: true,
      channel: 'chrome'
    });

    this.discoveryContext = await this.browser.newContext({
      userAgent: 'Mozilla/5.0 Chrome/120 Safari/537.36'
    });

    this.discoveryPage = await this.discoveryContext.newPage();
    await this.discoveryPage.addInitScript(() => {
      Object.defineProperty(navigator, 'webdriver', {
        get: () => false
      });
    });
  }

  getStatus() {
    return {
      ready: Boolean(this.browser),
      watcherCount: this.watchers.size,
      watcherIds: Array.from(this.watchers.keys())
    };
  }

  async fetchCurrentMatches() {
    if (!this.discoveryPage) {
      throw new Error('Worker not initialized');
    }

    const attempts = 3;

    for (let attempt = 1; attempt <= attempts; attempt += 1) {
      try {
        await this.discoveryPage.goto(DISCOVERY_URL, {
          waitUntil: 'domcontentloaded'
        });

        const response = await this.discoveryPage.waitForResponse((res) => {
          return res.url().includes('/v1/pages/matches/current') && res.status() === 200;
        });

        const data = await tryReadJson(response);
        if (!data?.matches) {
          throw new Error('Invalid matches payload');
        }

        return (data?.matches || []).map(extractMatch);
      } catch (err) {
        const isRetryable = isTransientNetworkError(err);
        const isLast = attempt === attempts;

        if (!isRetryable) {
          throw err;
        }

        if (isLast) {
          console.warn(
            `fetchCurrentMatches transient failure after ${attempts} attempts:`,
            err.message
          );
          return [];
        }

        console.warn(`fetchCurrentMatches transient failure (attempt ${attempt}/${attempts}):`, err.message);
        await sleep(attempt * 1000);
      }
    }

    return [];
  }

  isWatching(matchId) {
    return this.watchers.has(String(matchId));
  }

  async startWatcher(match) {
    const matchId = String(match.id);

    if (this.watchers.has(matchId)) {
      return false;
    }

    const context = await this.browser.newContext({
      userAgent: 'Mozilla/5.0 Chrome/120 Safari/537.36'
    });

    const page = await context.newPage();

    const onResponse = async (response) => {
      const url = response.url();

      try {
        let shouldStopAfterResponse = false;

        if (url.includes('/fastscore/message/base')) {
          const fullMessageId = new URL(url).searchParams.get('messageId');
          const normalized = normalizeMessageId(fullMessageId);
          const payload = await tryReadJson(response);

          if (!payload) {
            return;
          }

          if (normalized) {
            await this.mappingRepo.setMessageId(matchId, normalized);
          }

          await this.scoresRepo.setScore(matchId, {
            source: 'fastscore',
            payload,
            updatedAt: new Date().toISOString()
          });

          if (isMatchFinishedPayload(payload)) {
            shouldStopAfterResponse = true;
          }
        }

        if (url.includes('/v1/pages/match/details')) {
          const payload = await tryReadJson(response);

          if (!payload) {
            return;
          }

          const detailMatchId = payload?.match?.objectId;

          if (detailMatchId) {
            await this.mappingRepo.setMessageId(matchId, String(detailMatchId));
          }

          await this.scoresRepo.setScore(matchId, {
            source: 'details',
            payload,
            updatedAt: new Date().toISOString()
          });

          if (isMatchFinishedPayload(payload)) {
            shouldStopAfterResponse = true;
          }
        }

        if (shouldStopAfterResponse) {
          await this.stopWatcherForCompletedMatch(matchId);
        }
      } catch (err) {
        console.error(`Watcher response processing failed for ${matchId}:`, err.message);
      }
    };

    page.on('response', onResponse);

    await page.goto(getMatchUrl(match), {
      waitUntil: 'domcontentloaded'
    });

    this.watchers.set(matchId, {
      context,
      page,
      isClosing: false,
      startedAt: new Date().toISOString()
    });

    return true;
  }

  async stopWatcherForCompletedMatch(matchId) {
    const key = String(matchId);
    const watcher = this.watchers.get(key);

    if (!watcher || watcher.isClosing) {
      return false;
    }

    watcher.isClosing = true;

    await this.mappingRepo.setWatcherMeta(key, {
      status: 'match_finished',
      stoppedAt: new Date().toISOString()
    });

    return this.stopWatcher(key);
  }

  async stopWatcher(matchId) {
    const key = String(matchId);
    const watcher = this.watchers.get(key);

    if (!watcher) {
      return false;
    }

    await watcher.page.close({ runBeforeUnload: true }).catch(() => {});
    await watcher.context.close().catch(() => {});

    this.watchers.delete(key);
    return true;
  }

  async stopAllWatchers() {
    const ids = Array.from(this.watchers.keys());
    await Promise.all(ids.map((id) => this.stopWatcher(id)));
  }

  async close() {
    await this.stopAllWatchers();
    await this.discoveryPage?.close().catch(() => {});
    await this.discoveryContext?.close().catch(() => {});
    await this.browser?.close().catch(() => {});

    this.discoveryPage = null;
    this.discoveryContext = null;
    this.browser = null;
  }
}
