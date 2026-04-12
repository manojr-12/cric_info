import { createApp } from './src/api/app.js';
import { env } from './src/config/env.js';
import { initRedis, closeRedis } from './src/lib/redis.client.js';
import { MatchesRepository } from './src/repositories/matches.repo.js';
import { ScoresRepository } from './src/repositories/scores.repo.js';
import { MappingRepository } from './src/repositories/mapping.repo.js';
import { IngestionWorker } from './src/ingestion/ingestion.worker.js';
import { IngestionOrchestrator } from './src/ingestion/ingestion.orchestrator.js';

let orchestrator;
let server;

async function start() {
  const redis = await initRedis();

  const matchesRepo = new MatchesRepository(redis);
  const scoresRepo = new ScoresRepository(redis, env.SCORE_TTL_SEC);
  const mappingRepo = new MappingRepository(redis);

  const worker = new IngestionWorker({
    scoresRepo,
    mappingRepo
  });

  orchestrator = new IngestionOrchestrator({
    worker,
    matchesRepo,
    mappingRepo,
    maxConcurrency: env.WATCHER_MAX_CONCURRENCY,
    idleTtlSec: env.WATCHER_IDLE_TTL_SEC,
    refreshIntervalSec: env.MATCH_REFRESH_INTERVAL_SEC
  });

  await orchestrator.init();
  await orchestrator.start();

  const app = createApp({
    matchesRepo,
    scoresRepo,
    orchestrator,
    redis
  });

  server = app.listen(env.PORT, () => {
    console.log(`http://localhost:${env.PORT}`);
  });
}

async function shutdown() {
  if (server) {
    await new Promise((resolve) => server.close(resolve));
  }

  if (orchestrator) {
    await orchestrator.stop();
  }

  await closeRedis();
}

process.on('SIGINT', async () => {
  await shutdown();
  process.exit(0);
});

process.on('SIGTERM', async () => {
  await shutdown();
  process.exit(0);
});

start().catch(async (err) => {
  console.error('Fatal startup error:', err);
  await shutdown();
  process.exit(1);
});
