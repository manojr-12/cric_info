import { sendError } from './response.js';
import { series } from '../config/series.js';

export const createMatchesController = ({ matchesRepo, scoresRepo, orchestrator }) => {
  const getMatches = async (req, res) => {
    const matches = await matchesRepo.getAllMatches();
    return res.json(matches);
  };

  const getLive = async (req, res) => {
    const live = await matchesRepo.getLiveMatches(series);
    return res.json(live);
  };

  const getScore = async (req, res) => {
    const { matchId } = req.query;

    if (!matchId) {
      return sendError(res, 400, 'BAD_REQUEST', 'matchId required');
    }

    await orchestrator.touchWatcher(matchId);

    const score = await scoresRepo.getScore(matchId);

    if (!score) {
      const started = await orchestrator.requestMatch(matchId);

      if (!started) {
        return sendError(res, 404, 'SCORE_NOT_FOUND', 'No score yet', { matchId: String(matchId) });
      }

      return res.status(202).json({
        matchId: String(matchId),
        status: 'pending',
        message: 'Watcher started. Score warming up.'
      });
    }

    return res.json(score);
  };

  const setPreference = async (req, res) => {
    const { matchId } = req.body || {};

    if (!matchId) {
      return sendError(res, 400, 'BAD_REQUEST', 'matchId required');
    }

    const started = await orchestrator.requestMatch(matchId);

    if (!started) {
      return sendError(
        res,
        409,
        'WATCHER_NOT_STARTED',
        'Could not start watcher for match',
        { matchId: String(matchId) }
      );
    }

    return res.json({ success: true, matchId: String(matchId) });
  };

  const getWatchers = async (req, res) => {
    const watchers = await orchestrator.listWatchers();
    return res.json({ watchers });
  };

  return {
    getMatches,
    getLive,
    getScore,
    setPreference,
    getWatchers
  };
};
