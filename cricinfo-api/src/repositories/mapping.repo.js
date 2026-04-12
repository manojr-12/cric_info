const messageKey = (matchId) => `cric:map:message:${matchId}`;
const watcherKey = (matchId) => `cric:watcher:${matchId}`;
const WATCHERS_SET_KEY = 'cric:watchers:active';
const PREFERRED_SET_KEY = 'cric:matches:preferred';

export class MappingRepository {
  constructor(redis) {
    this.redis = redis;
  }

  async setMessageId(matchId, messageId) {
    await this.redis.set(messageKey(matchId), messageId);
  }

  async getMessageId(matchId) {
    return this.redis.get(messageKey(matchId));
  }

  async addPreferredMatch(matchId) {
    await this.redis.sAdd(PREFERRED_SET_KEY, String(matchId));
  }

  async getPreferredMatches() {
    return this.redis.sMembers(PREFERRED_SET_KEY);
  }

  async removePreferredMatch(matchId) {
    await this.redis.sRem(PREFERRED_SET_KEY, String(matchId));
  }

  async setWatcherMeta(matchId, patch) {
    const current = await this.getWatcherMeta(matchId);
    const next = {
      matchId: String(matchId),
      ...current,
      ...patch,
      updatedAt: new Date().toISOString()
    };

    await this.redis.set(watcherKey(matchId), JSON.stringify(next));

    if (next.status === 'active' || next.status === 'starting') {
      await this.redis.sAdd(WATCHERS_SET_KEY, String(matchId));
    } else {
      await this.redis.sRem(WATCHERS_SET_KEY, String(matchId));
    }

    return next;
  }

  async getWatcherMeta(matchId) {
    const raw = await this.redis.get(watcherKey(matchId));
    return raw ? JSON.parse(raw) : null;
  }

  async clearWatcherMeta(matchId) {
    await this.redis.del(watcherKey(matchId));
    await this.redis.sRem(WATCHERS_SET_KEY, String(matchId));
  }

  async getActiveWatcherIds() {
    return this.redis.sMembers(WATCHERS_SET_KEY);
  }

  async getAllWatcherMeta() {
    const ids = await this.getActiveWatcherIds();
    const metas = await Promise.all(ids.map((id) => this.getWatcherMeta(id)));

    return metas.filter(Boolean);
  }
}
