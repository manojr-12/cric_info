import express from 'express';
import { getMatches, getLive, getScore , setPreference} from '../controllers/matches.controller.js';

const router = express.Router();

router.get('/', getMatches);
router.get('/live', getLive);
router.get('/score', getScore);
router.post('/preference', setPreference);

export default router;