import { series } from '../config/series.js';

export class IngestionOrchestrator {
  constructor({
    worker,
    matchesRepo,
    mappingRepo,
    maxConcurrency,
    idleTtlSec,
    refreshIntervalSec
  }) {
    this.worker = worker;
    this.matchesRepo = matchesRepo;
    this.mappingRepo = mappingRepo;
    this.maxConcurrency = maxConcurrency;
    this.idleTtlSec = idleTtlSec;
    this.refreshIntervalSec = refreshIntervalSec;
    this.refreshTimer = null;
  }

  async init() {
    await this.worker.init();
    await this.fetchAndStoreMatches();
    await this.recoverWatchers();
  }

  async start() {
    await this.refreshMatchesAndWatchers();

    this.refreshTimer = setInterval(async () => {
      try {
        await this.refreshMatchesAndWatchers();
      } catch (err) {
        console.error('Periodic refresh failed:', err.message);
      }
    }, this.refreshIntervalSec * 1000);
  }

  async stop() {
    if (this.refreshTimer) {
      clearInterval(this.refreshTimer);
      this.refreshTimer = null;
    }

    await this.worker.close();
  }

  async recoverWatchers() {
    const activeIds = await this.mappingRepo.getActiveWatcherIds();

    if (!activeIds.length) {
      return;
    }

    const allMatches = await this.matchesRepo.getAllMatches();
    const byId = new Map(allMatches.map((match) => [String(match.id), match]));

    for (const matchId of activeIds) {
      const match = byId.get(String(matchId));

      if (!match) {
        await this.mappingRepo.clearWatcherMeta(matchId);
        continue;
      }

      if (this.worker.isWatching(matchId)) {
        continue;
      }

      try {
        await this.worker.startWatcher(match);
        await this.mappingRepo.setWatcherMeta(matchId, {
          status: 'active',
          startedAt: new Date().toISOString(),
          lastSeenAt: new Date().toISOString()
        });
      } catch (err) {
        await this.mappingRepo.setWatcherMeta(matchId, {
          status: 'error',
          lastError: err.message
        });
      }
    }
  }

  async refreshMatchesAndWatchers() {
    const matches = await this.fetchAndStoreMatches();

    const liveFiltered = matches.filter(
      (match) => match.isLive && series.includes(match.series)
    );

    const preferred = await this.mappingRepo.getPreferredMatches();
    const preferredSet = new Set(preferred.map(String));

    const desired = [];
    const seen = new Set();

    const addDesired = (match) => {
      const id = String(match.id);

      if (seen.has(id)) {
        return;
      }

      seen.add(id);
      desired.push(match);
    };

    for (const match of matches) {
      if (preferredSet.has(String(match.id))) {
        addDesired(match);
      }
    }

    for (const match of liveFiltered) {
      addDesired(match);
    }

    await this.reconcileWatchers(desired);
    await this.stopInactiveWatchers(desired, preferredSet);
  }

  async fetchAndStoreMatches() {
    const matches = await this.worker.fetchCurrentMatches();
    await this.matchesRepo.setMatches(matches);
    return matches;
  }

  async reconcileWatchers(desiredMatches) {
    const activeMeta = await this.mappingRepo.getAllWatcherMeta();
    const activeCount = activeMeta.filter((item) => item.status === 'active').length;
    const capacity = Math.max(this.maxConcurrency - activeCount, 0);

    if (!capacity) {
      return;
    }

    const toStart = desiredMatches
      .filter((match) => !this.worker.isWatching(match.id))
      .slice(0, capacity);

    await Promise.all(toStart.map((match) => this.startWatcher(match)));
  }

  async startWatcher(match) {
    const matchId = String(match.id);

    if (this.worker.isWatching(matchId)) {
      return false;
    }

    await this.mappingRepo.setWatcherMeta(matchId, {
      status: 'starting',
      startedAt: new Date().toISOString(),
      lastRequestedAt: new Date().toISOString()
    });

    try {
      await this.worker.startWatcher(match);
      await this.mappingRepo.setWatcherMeta(matchId, {
        status: 'active',
        lastSeenAt: new Date().toISOString()
      });
      return true;
    } catch (err) {
      await this.mappingRepo.setWatcherMeta(matchId, {
        status: 'error',
        lastError: err.message
      });
      return false;
    }
  }

  async stopWatcher(matchId, reason = 'stopped') {
    const didStop = await this.worker.stopWatcher(matchId);

    await this.mappingRepo.setWatcherMeta(matchId, {
      status: reason,
      stoppedAt: new Date().toISOString()
    });

    return didStop;
  }

  async stopInactiveWatchers(desiredMatches, preferredSet) {
    const desiredSet = new Set(desiredMatches.map((match) => String(match.id)));
    const activeWatchers = await this.mappingRepo.getAllWatcherMeta();
    const now = Date.now();

    for (const watcher of activeWatchers) {
      const matchId = String(watcher.matchId);
      const lastRequestedAt = watcher.lastRequestedAt
        ? new Date(watcher.lastRequestedAt).getTime()
        : now;
      const idleSec = Math.floor((now - lastRequestedAt) / 1000);
      const isDesired = desiredSet.has(matchId);
      const isPreferred = preferredSet.has(matchId);

      if (!isDesired && !isPreferred) {
        await this.stopWatcher(matchId, 'inactive');
        continue;
      }

      if (!isPreferred && idleSec > this.idleTtlSec) {
        await this.stopWatcher(matchId, 'idle_timeout');
      }
    }
  }

  async requestMatch(matchId) {
    const match = await this.matchesRepo.getMatchById(matchId);

    if (!match) {
      return false;
    }

    await this.mappingRepo.addPreferredMatch(matchId);
    await this.mappingRepo.setWatcherMeta(matchId, {
      lastRequestedAt: new Date().toISOString()
    });

    if (this.worker.isWatching(matchId)) {
      return true;
    }

    const activeMeta = await this.mappingRepo.getAllWatcherMeta();
    const activeCount = activeMeta.filter((item) => item.status === 'active').length;

    if (activeCount >= this.maxConcurrency) {
      return false;
    }

    return this.startWatcher(match);
  }

  async touchWatcher(matchId) {
    await this.mappingRepo.setWatcherMeta(matchId, {
      lastRequestedAt: new Date().toISOString()
    });
  }

  async listWatchers() {
    return this.mappingRepo.getAllWatcherMeta();
  }

  async health() {
    return {
      worker: this.worker.getStatus(),
      refreshIntervalSec: this.refreshIntervalSec,
      maxConcurrency: this.maxConcurrency,
      idleTtlSec: this.idleTtlSec
    };
  }
}
