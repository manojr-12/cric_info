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
  if (!full) {
    return null;
  }

  const parts = full.split('-');
  return parts[1] ? `md-${parts[1]}` : full;
}
