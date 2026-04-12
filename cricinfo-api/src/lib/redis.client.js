import { createClient } from 'redis';
import { env } from '../config/env.js';

let client;

export async function initRedis() {
  if (client?.isOpen) {
    return client;
  }

  client = createClient({
    url: env.REDIS_URL,
    socket: {
      reconnectStrategy(retries) {
        return Math.min(retries * 100, 3000);
      }
    }
  });

  client.on('error', (err) => {
    console.error('Redis error:', err.message);
  });

  await client.connect();
  return client;
}

export function getRedis() {
  if (!client) {
    throw new Error('Redis client not initialized');
  }

  return client;
}

export async function closeRedis() {
  if (client?.isOpen) {
    await client.quit();
  }
}
