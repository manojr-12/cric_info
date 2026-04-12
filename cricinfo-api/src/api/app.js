import express from 'express';
import { createMatchesController } from './matches.controller.js';
import { createMatchesRouter } from './matches.routes.js';
import { sendError } from './response.js';

export const createApp = ({ matchesRepo, scoresRepo, orchestrator, redis }) => {
  const app = express();
  const matchesController = createMatchesController({
    matchesRepo,
    scoresRepo,
    orchestrator
  });

  app.use(express.json());
  app.use('/matches', createMatchesRouter(matchesController));

  app.get('/health', async (req, res) => {
    const [orchestratorHealth] = await Promise.all([orchestrator.health()]);

    return res.json({
      status: 'ok',
      redis: { connected: redis.isOpen },
      ...orchestratorHealth
    });
  });

  app.get('/', (req, res) => {
    res.send('Cricket API running');
  });

  app.use((err, req, res, next) => {
    console.error('Unhandled error:', err);

    if (res.headersSent) {
      return next(err);
    }

    return sendError(res, 500, 'INTERNAL_SERVER_ERROR', 'Unexpected server error');
  });

  return app;
};
