import { latestMatches } from '../state/store.js';
import { series } from '../config/series.js';
import { getPage } from '../services/browser.service.js';


export function extractMatch(match) {
    return {
      id: match.objectId,
      slug: match.slug,
  
      seriesSlug: match.series?.slug,
      seriesObjectId: match.series?.objectId,
  
      title: match.title,
      series: match.series?.name,
  
      team1: match.teams?.[0]?.team?.name,
      team2: match.teams?.[1]?.team?.name,
  
      isLive: match.state === 'LIVE',
  
      team1Info: {
        score: match.teams?.[0]?.score,
        overs: match.teams?.[0]?.scoreInfo
      },
  
      team2Info: {
        score: match.teams?.[1]?.score,
        overs: match.teams?.[1]?.scoreInfo
      },
  
      text: match.statusText
    };
  }
  
  export function getMatchUrl(match) {
    const fullSeriesSlug = `${match.seriesSlug}-${match.seriesObjectId}`;
  
    return `https://www.espncricinfo.com/series/${fullSeriesSlug}/${match.slug}-${match.id}/live-cricket-score`;
  }
  
  export function normalizeMessageId(full) {
    const parts = full.split('-');
    return `md-${parts[1]}`;
  }
  
  export const sleep = (ms) => new Promise(r => setTimeout(r, ms));



  export function getAllMatches() {
    return latestMatches;
  }
  
  export function getLiveMatches() {
    return latestMatches.filter(m =>
      m.isLive && series.includes(m.series)
    );
  }

  export async function openMatchById(matchId) {
    const match = latestMatches.find(m => String(m.id) === String(matchId));
  
    if (!match) {
      console.log(`❌ Match not found: ${matchId}`);
      return;
    }
  
    const url = getMatchUrl(match);
  
    console.log('🌐 Opening preferred match:', matchId);

  const page = getPage();
    await page.goto(url, { waitUntil: 'domcontentloaded' });
  
    // Wait for BOTH APIs
    // await Promise.all([
    //   page.waitForResponse(res =>
    //     res.url().includes('/fastscore/message/base')
    //   ),
    //   page.waitForResponse(res =>
    //     res.url().includes('/v1/pages/match/details')
    //   )
    // ]);
  
    console.log(`✅ Listening started → ${matchId}`);
  }