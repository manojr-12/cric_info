const toInt = (value, fallback) => {
  const parsed = Number.parseInt(value ?? '', 10);
  return Number.isFinite(parsed) ? parsed : fallback;
};

export const env = {
  PORT: toInt(process.env.PORT, 3000),
  REDIS_URL: process.env.REDIS_URL || 'redis://127.0.0.1:6379',
  WATCHER_MAX_CONCURRENCY: toInt(process.env.WATCHER_MAX_CONCURRENCY, 6),
  WATCHER_IDLE_TTL_SEC: toInt(process.env.WATCHER_IDLE_TTL_SEC, 900),
  MATCH_REFRESH_INTERVAL_SEC: toInt(process.env.MATCH_REFRESH_INTERVAL_SEC, 3600),
  SCORE_TTL_SEC: toInt(process.env.SCORE_TTL_SEC, 1200)
};
