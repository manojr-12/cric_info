import { matchIdToMessageId, liveScores } from '../state/store.js';
import { setPreferredMatch } from '../state/preference.js';
import {getLiveMatches, getAllMatches,openMatchById} from '../utils/helper.js';

export const getMatches = (req, res) => {
  res.json(getAllMatches());
};

export const getLive = (req, res) => {
  res.json(getLiveMatches());
};

export const getScore = (req, res) => {
  const { matchId } = req.query;
  if (!matchId) return res.status(400).json({ error: 'matchId required' });

  const messageId = matchIdToMessageId[matchId];
  if (!messageId) return res.status(404).json({ error: 'No messageId yet' });

  const data = liveScores[messageId];
  if (!data) return res.status(404).json({ error: 'No score yet' });

  res.json(data);
};


export const setPreference = async (req, res) => {
  const { matchId } = req.body;

  if (!matchId) {
    return res.status(400).json({ error: 'matchId required' });
  }

  setPreferredMatch(matchId);

  console.log(`⭐ Added preference → ${matchId}`);

  // 🔥 Immediately start listening
  await openMatchById(matchId);

  res.json({ success: true, matchId });
};