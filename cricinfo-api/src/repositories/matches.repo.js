const MATCHES_KEY = 'cric:matches:current';

export class MatchesRepository {
  constructor(redis) {
    this.redis = redis;
  }

  async setMatches(matches) {
    const payload = {
      updatedAt: new Date().toISOString(),
      matches
    };

    await this.redis.set(MATCHES_KEY, JSON.stringify(payload));
    return payload;
  }

  async getSnapshot() {
    const raw = await this.redis.get(MATCHES_KEY);

    if (!raw) {
      return { updatedAt: null, matches: [] };
    }

    return JSON.parse(raw);
  }

  async getAllMatches() {
    const snapshot = await this.getSnapshot();
    return snapshot.matches;
  }

  async getLiveMatches(seriesFilter = []) {
    const matches = await this.getAllMatches();

    return matches.filter((match) => {
      if (!match.isLive) {
        return false;
      }

      if (!seriesFilter.length) {
        return true;
      }

      return seriesFilter.includes(match.series);
    });
  }

  async getMatchById(matchId) {
    const matches = await this.getAllMatches();
    return matches.find((match) => String(match.id) === String(matchId)) || null;
  }
}
