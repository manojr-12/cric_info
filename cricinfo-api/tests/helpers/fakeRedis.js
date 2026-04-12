export class FakeRedis {
  constructor() {
    this.kv = new Map();
    this.sets = new Map();
  }

  async set(key, value, options = {}) {
    this.kv.set(key, { value, options });
    return 'OK';
  }

  async get(key) {
    const entry = this.kv.get(key);
    return entry ? entry.value : null;
  }

  async del(key) {
    this.kv.delete(key);
    return 1;
  }

  async sAdd(key, value) {
    const set = this.sets.get(key) || new Set();
    set.add(String(value));
    this.sets.set(key, set);
    return 1;
  }

  async sMembers(key) {
    return Array.from(this.sets.get(key) || []);
  }

  async sRem(key, value) {
    const set = this.sets.get(key);

    if (!set) {
      return 0;
    }

    set.delete(String(value));
    this.sets.set(key, set);
    return 1;
  }

  getSet(key) {
    return this.sets.get(key) || new Set();
  }

  getSetOptions(key) {
    return this.kv.get(key)?.options;
  }
}
