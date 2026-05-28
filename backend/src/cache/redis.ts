import { createClient } from "redis";
import type { CacheStore } from "./memory.js";
import { createMemoryCache } from "./memory.js";
import type { Recipe } from "../schema/recipe.js";

export function createHybridCache(redisUrl?: string, logger?: any): CacheStore {
  if (!redisUrl) {
    const msg = "[cache] REDIS_URL not set — falling back to local memory cache";
    if (logger && typeof logger.warn === "function") {
      logger.warn(msg);
    } else {
      console.warn(msg);
    }
    return createMemoryCache();
  }

  const client = createClient({ url: redisUrl });
  let isConnected = false;

  client.on("error", (err) => {
    if (logger && typeof logger.error === "function") {
      logger.error({ err: err.message }, "[cache] Redis connection error");
    } else {
      console.error("[cache] Redis connection error:", err.message);
    }
  });

  client
    .connect()
    .then(() => {
      isConnected = true;
      const msg = "[cache] Connected to Redis successfully";
      if (logger && typeof logger.info === "function") {
        logger.info(msg);
      } else {
        console.log(msg);
      }
    })
    .catch((err) => {
      const msg = `[cache] Failed to connect to Redis: ${err.message}. Falling back to memory cache.`;
      if (logger && typeof logger.error === "function") {
        logger.error(msg);
      } else {
        console.error(msg);
      }
    });

  // Keep a local memory cache as fallback
  const memoryFallback = createMemoryCache();

  return {
    async get(key) {
      if (!isConnected) {
        return memoryFallback.get(key);
      }
      try {
        const value = await client.get(key);
        if (!value) return null;
        return JSON.parse(value) as Recipe;
      } catch (err) {
        if (logger && typeof logger.error === "function") {
          logger.error({ err }, "[cache] Failed to read from Redis, falling back to memory");
        }
        return memoryFallback.get(key);
      }
    },
    async set(key, recipe) {
      if (!isConnected) {
        memoryFallback.set(key, recipe);
        return;
      }
      try {
        // Cache with 24 hours (86400 seconds) expiration
        await client.set(key, JSON.stringify(recipe), { EX: 86400 });
      } catch (err) {
        if (logger && typeof logger.error === "function") {
          logger.error({ err }, "[cache] Failed to write to Redis, writing to memory fallback instead");
        }
        memoryFallback.set(key, recipe);
      }
    },
  };
}
