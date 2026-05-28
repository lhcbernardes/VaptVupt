//
// Fastify entry point. Exposes a single endpoint:
//
//   POST /parse-url   { url: string }   → 200 { recipe: Recipe }
//
// Plus a `GET /health` for Railway/Fly liveness probes.
//

import "dotenv/config";
import Fastify from "fastify";
import cors from "@fastify/cors";
import { z } from "zod";
import { extractFromURL } from "./parsers/index.js";
import { logUsage, structureRecipe } from "./llm/anthropic.js";
import { createHybridCache } from "./cache/redis.js";

const PORT = Number(process.env.PORT ?? 3000);
const APP_API_KEY = process.env.APP_API_KEY ?? "";

const ParseRequestSchema = z.object({
  url: z.string().url(),
});

async function main() {
  if (!process.env.ANTHROPIC_API_KEY) {
    throw new Error("ANTHROPIC_API_KEY is required.");
  }
  if (!process.env.OPENAI_API_KEY) {
    console.warn(
      "[startup] OPENAI_API_KEY not set — video URLs (Instagram/TikTok/YouTube) will fail with a 500 from the Whisper client.",
    );
  }

  const app = Fastify({ logger: { level: process.env.LOG_LEVEL ?? "info" } });
  await app.register(cors, { origin: true });

  const cache = createHybridCache(process.env.REDIS_URL, app.log);

  // Auth gate — only enforced when APP_API_KEY is set.
  app.addHook("onRequest", async (req, reply) => {
    if (!APP_API_KEY) return;
    if (req.url === "/health") return;
    const header = req.headers.authorization;
    if (header !== `Bearer ${APP_API_KEY}`) {
      reply.code(401).send({ error: "unauthorized" });
    }
  });

  app.get("/health", async () => ({ status: "ok" }));

  app.post("/parse-url", async (req, reply) => {
    const parsed = ParseRequestSchema.safeParse(req.body);
    if (!parsed.success) {
      reply.code(400);
      return { error: "invalid_request", details: parsed.error.flatten() };
    }
    const url = new URL(parsed.data.url);
    const cacheKey = url.toString();

    const hit = await cache.get(cacheKey);
    if (hit) {
      app.log.info({ url: cacheKey }, "cache hit");
      return { recipe: hit, cached: true };
    }

    try {
      const extracted = await extractFromURL(url, req.log);
      const recipe = await structureRecipe(extracted.rawText, extracted.sourceHint, req.log);
      await cache.set(cacheKey, recipe);
      return { recipe, cached: false };
    } catch (err) {
      const message = err instanceof Error ? err.message : "unknown_error";
      app.log.error({ url: cacheKey, err: message }, "parse failed");

      // Quick categorization for the client to show the right alert.
      let code = "parse_failed";
      if (message.includes("yt-dlp") || message.includes("duration"))
        code = "video_unavailable";
      if (message.includes("LLM") || message.includes("schema"))
        code = "structuring_failed";
      if (message.includes("retornou 4")) code = "page_unavailable";

      reply.code(422);
      return { error: code, message };
    }
  });

  // Telemetry: log Anthropic usage when present. Hooked at the request scope
  // would be cleaner but the SDK doesn't surface usage via headers — we log
  // inline inside the LLM client. This `logUsage` re-export is here so
  // future routes don't have to reach into the LLM module.
  void logUsage;

  await app.listen({ port: PORT, host: "0.0.0.0" });
  app.log.info(`listening on :${PORT}`);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
