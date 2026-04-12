import test from 'node:test';
import assert from 'node:assert/strict';
import { FakeRedis } from './helpers/fakeRedis.js';
import { MatchesRepository } from '../src/repositories/matches.repo.js';
import { MappingRepository } from '../src/repositories/mapping.repo.js';
import { IngestionOrchestrator } from '../src/ingestion/ingestion.orchestrator.js';

class FakeWorker {
  constructor(matches = []) {
    this.matches = matches;
    this.watching = new Set();
    this.startCalls = [];
    this.ready = false;
  }

  async init() {
    this.ready = true;
  }

  async fetchCurrentMatches() {
    return this.matches;
  }

  isWatching(matchId) {
    return this.watching.has(String(matchId));
  }

  async startWatcher(match) {
    this.startCalls.push(String(match.id));
    this.watching.add(String(match.id));
    return true;
  }

  async stopWatcher(matchId) {
    this.watching.delete(String(matchId));
    return true;
  }

  async close() {
    this.watching.clear();
  }

  getStatus() {
    return {
      ready: this.ready,
      watcherCount: this.watching.size,
      watcherIds: Array.from(this.watching)
    };
  }
}

test('requestMatch is idempotent for an already-started watcher', async () => {
  const redis = new FakeRedis();
  const matchesRepo = new MatchesRepository(redis);
  const mappingRepo = new MappingRepository(redis);
  const worker = new FakeWorker([{ id: '101', isLive: true, series: 'IPL' }]);

  await matchesRepo.setMatches([{ id: '101', isLive: true, series: 'IPL' }]);

  const orchestrator = new IngestionOrchestrator({
    worker,
    matchesRepo,
    mappingRepo,
    maxConcurrency: 3,
    idleTtlSec: 60,
    refreshIntervalSec: 120
  });

  await orchestrator.init();
  const first = await orchestrator.requestMatch('101');
  const second = await orchestrator.requestMatch('101');

  assert.equal(first, true);
  assert.equal(second, true);
  assert.equal(worker.startCalls.length, 1);
});

test('recoverWatchers restarts active watcher metadata on init', async () => {
  const redis = new FakeRedis();
  const matchesRepo = new MatchesRepository(redis);
  const mappingRepo = new MappingRepository(redis);
  const worker = new FakeWorker([{ id: '202', isLive: true, series: 'IPL' }]);

  await matchesRepo.setMatches([{ id: '202', isLive: true, series: 'IPL' }]);
  await mappingRepo.setWatcherMeta('202', { status: 'active' });

  const orchestrator = new IngestionOrchestrator({
    worker,
    matchesRepo,
    mappingRepo,
    maxConcurrency: 3,
    idleTtlSec: 60,
    refreshIntervalSec: 120
  });

  await orchestrator.init();

  assert.equal(worker.isWatching('202'), true);
  assert.equal(worker.startCalls.length, 1);
});
