const scoreKey = (matchId) => `cric:score:${matchId}`;

export class ScoresRepository {
  constructor(redis, ttlSec) {
    this.redis = redis;
    this.ttlSec = ttlSec;
  }

  async setScore(matchId, score) {
    const payload = {
      matchId: String(matchId),
      source: score.source,
      updatedAt: score.updatedAt || new Date().toISOString(),
      payload: score.payload
    };

    await this.redis.set(scoreKey(matchId), JSON.stringify(payload), {
      EX: this.ttlSec
    });

    return payload;
  }

  async getScore(matchId) {
    const raw = await this.redis.get(scoreKey(matchId));
    return raw ? JSON.parse(raw) : null;
  }
}
