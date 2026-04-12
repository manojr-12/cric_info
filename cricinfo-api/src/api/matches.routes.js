import express from 'express';

export const createMatchesRouter = (controller) => {
  const router = express.Router();

  router.get('/', controller.getMatches);
  router.get('/live', controller.getLive);
  router.get('/score', controller.getScore);
  router.post('/preference', controller.setPreference);
  router.get('/watchers', controller.getWatchers);

  return router;
};
