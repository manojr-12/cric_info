import { getPage } from './browser.service.js';
import { extractMatch, getMatchUrl, sleep } from '../utils/helper.js';
import { latestMatches,matchIds } from '../state/store.js';
import { series } from '../config/series.js';

export async function fetchMatches() {
  const page = getPage();

  await page.goto('https://www.espncricinfo.com/live-cricket-score', {
    waitUntil: 'domcontentloaded'
  });

  const response = await page.waitForResponse(res =>
    res.url().includes('/v1/pages/matches/current') &&
    res.status() === 200
  );

  const data = await response.json();

  latestMatches.length = 0;
  latestMatches.push(...(data?.matches?.map(extractMatch) || []));
  matchIds.clear();

  for (const match of latestMatches) {
    if (match.isLive && series.includes(match.series)) {
      matchIds.add(match.id);
    }
  }

  console.log('Matches:', latestMatches.length);
}

export async function openLiveMatches() {
  const page = getPage();

  for (const match of latestMatches) {
    if (!match.isLive || !series.includes(match.series)) continue;
    await page.goto(getMatchUrl(match), {
      waitUntil: 'domcontentloaded'
    });
  }
}

export async function startPolling() {
  console.log('🚀 Starting polling...');

  // Step 1: initial fetch with retry
  await initialFetchWithRetry();

  // Step 2: schedule hourly updates
  setInterval(async () => {
    try {
      console.log('⏱ Refreshing matches (hourly)...');

      await fetchMatches();
      await openLiveMatches();

    } catch (err) {
      console.log('❌ Hourly refresh failed:', err.message);
    }
  }, 60 * 60 * 1000); // 60 mins
}


async function initialFetchWithRetry() {
  while (true) {
    try {
      console.log('🔄 Initial fetch...');

      await fetchMatches();

      if (latestMatches.length > 0) {
        console.log('✅ Initial fetch success');

        await openLiveMatches();
        break; // ✅ exit loop after success
      } else {
        console.log('⚠️ No matches, retry in 10s...');
        await sleep(10 * 1000);
      }

    } catch (err) {
      console.log('❌ Fetch failed, retry in 10s...',err);
      await sleep(10 * 1000);
    }
  }
}