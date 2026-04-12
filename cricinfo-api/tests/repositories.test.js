import test from 'node:test';
import assert from 'node:assert/strict';
import { FakeRedis } from './helpers/fakeRedis.js';
import { MatchesRepository } from '../src/repositories/matches.repo.js';
import { ScoresRepository } from '../src/repositories/scores.repo.js';
import { MappingRepository } from '../src/repositories/mapping.repo.js';

test('matches repository stores and filters matches', async () => {
  const redis = new FakeRedis();
  const repo = new MatchesRepository(redis);

  await repo.setMatches([
    { id: '1', isLive: true, series: 'IPL' },
    { id: '2', isLive: false, series: 'IPL' },
    { id: '3', isLive: true, series: 'PSL' }
  ]);

  const all = await repo.getAllMatches();
  const live = await repo.getLiveMatches(['IPL']);

  assert.equal(all.length, 3);
  assert.deepEqual(live.map((m) => m.id), ['1']);
});

test('scores repository writes standardized payload with ttl', async () => {
  const redis = new FakeRedis();
  const repo = new ScoresRepository(redis, 300);

  const saved = await repo.setScore('42', {
    source: 'details',
    payload: { score: '100/1' }
  });

  const loaded = await repo.getScore('42');

  assert.equal(saved.matchId, '42');
  assert.equal(saved.source, 'details');
  assert.equal(loaded.payload.score, '100/1');
  assert.deepEqual(redis.getSetOptions('cric:score:42'), { EX: 300 });
});

test('mapping repository tracks watcher metadata and active set', async () => {
  const redis = new FakeRedis();
  const repo = new MappingRepository(redis);

  await repo.setWatcherMeta('12', { status: 'active' });
  await repo.setWatcherMeta('13', { status: 'starting' });
  await repo.setWatcherMeta('13', { status: 'error' });

  const activeIds = await repo.getActiveWatcherIds();
  const meta12 = await repo.getWatcherMeta('12');

  assert.deepEqual(activeIds, ['12']);
  assert.equal(meta12.status, 'active');
});
