//
// Single-process in-memory LRU cache for parsed recipes. Trivial to swap
// for Redis/Upstash later — `CacheStore` is the only contract callers see.
//
// Why cache: a single Instagram parse can cost ~1¢ (Whisper + Claude).
// People share viral reels — second person clicking the same link is free.
//

import type { Recipe } from "../schema/recipe.js";

interface Entry {
  recipe: Recipe;
  insertedAt: number;
}

export interface CacheStore {
  get(key: string): Recipe | null;
  set(key: string, recipe: Recipe): void;
}

export function createMemoryCache(maxEntries = 500, ttlMs = 1000 * 60 * 60 * 24): CacheStore {
  const data = new Map<string, Entry>();

  return {
    get(key) {
      const entry = data.get(key);
      if (!entry) return null;
      if (Date.now() - entry.insertedAt > ttlMs) {
        data.delete(key);
        return null;
      }
      // LRU bump.
      data.delete(key);
      data.set(key, entry);
      return entry.recipe;
    },
    set(key, recipe) {
      if (data.size >= maxEntries) {
        const oldest = data.keys().next().value;
        if (oldest) data.delete(oldest);
      }
      data.set(key, { recipe, insertedAt: Date.now() });
    },
  };
}
