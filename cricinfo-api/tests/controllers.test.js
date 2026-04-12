import test from 'node:test';
import assert from 'node:assert/strict';
import { createMatchesController } from '../src/api/matches.controller.js';

function createMockRes() {
  return {
    statusCode: 200,
    payload: null,
    status(code) {
      this.statusCode = code;
      return this;
    },
    json(value) {
      this.payload = value;
      return this;
    }
  };
}

test('getScore validates missing matchId', async () => {
  const controller = createMatchesController({
    matchesRepo: {},
    scoresRepo: {},
    orchestrator: { touchWatcher: async () => {}, requestMatch: async () => false }
  });

  const req = { query: {} };
  const res = createMockRes();

  await controller.getScore(req, res);

  assert.equal(res.statusCode, 400);
  assert.deepEqual(res.payload, {
    error: {
      code: 'BAD_REQUEST',
      message: 'matchId required'
    }
  });
});

test('getScore returns pending when repository has no payload but watcher starts', async () => {
  const controller = createMatchesController({
    matchesRepo: {},
    scoresRepo: { getScore: async () => null },
    orchestrator: { touchWatcher: async () => {}, requestMatch: async () => true }
  });

  const req = { query: { matchId: '321' } };
  const res = createMockRes();

  await controller.getScore(req, res);

  assert.equal(res.statusCode, 202);
  assert.equal(res.payload.status, 'pending');
  assert.equal(res.payload.matchId, '321');
});

test('getScore returns SCORE_NOT_FOUND when repository has no payload and watcher cannot start', async () => {
  const controller = createMatchesController({
    matchesRepo: {},
    scoresRepo: { getScore: async () => null },
    orchestrator: { touchWatcher: async () => {}, requestMatch: async () => false }
  });

  const req = { query: { matchId: '321' } };
  const res = createMockRes();

  await controller.getScore(req, res);

  assert.equal(res.statusCode, 404);
  assert.equal(res.payload.error.code, 'SCORE_NOT_FOUND');
  assert.equal(res.payload.error.details.matchId, '321');
});

test('getScore returns standardized score payload on success', async () => {
  const result = {
    matchId: '321',
    source: 'details',
    updatedAt: '2026-01-01T00:00:00.000Z',
    payload: { hello: 'world' }
  };

  const controller = createMatchesController({
    matchesRepo: {},
    scoresRepo: { getScore: async () => result },
    orchestrator: { touchWatcher: async () => {}, requestMatch: async () => false }
  });

  const req = { query: { matchId: '321' } };
  const res = createMockRes();

  await controller.getScore(req, res);

  assert.equal(res.statusCode, 200);
  assert.deepEqual(res.payload, result);
});

test('setPreference validates required matchId and concurrency failures', async () => {
  const failingController = createMatchesController({
    matchesRepo: {},
    scoresRepo: {},
    orchestrator: { requestMatch: async () => false }
  });

  const missingReq = { body: {} };
  const missingRes = createMockRes();
  await failingController.setPreference(missingReq, missingRes);

  assert.equal(missingRes.statusCode, 400);
  assert.equal(missingRes.payload.error.code, 'BAD_REQUEST');

  const conflictReq = { body: { matchId: '99' } };
  const conflictRes = createMockRes();
  await failingController.setPreference(conflictReq, conflictRes);

  assert.equal(conflictRes.statusCode, 409);
  assert.equal(conflictRes.payload.error.code, 'WATCHER_NOT_STARTED');
});
