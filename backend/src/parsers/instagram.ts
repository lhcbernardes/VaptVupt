//
// Instagram (and TikTok / YouTube Shorts) parser. Downloads the audio with
// yt-dlp, runs OpenAI Whisper, and combines the transcript with the post's
// public caption. The result is a single text blob ready for the LLM.
//

import { rm } from "node:fs/promises";
import { downloadAudio } from "../audio/ytdlp.js";
import { transcribe } from "../audio/whisper.js";

import { createConcurrencyLimiter } from "../utils/limit.js";
import { detectLanguage } from "../utils/lang.js";

// Limit active yt-dlp & Whisper conversions to 2 concurrent tasks.
const limit = createConcurrencyLimiter(2);

export interface InstagramExtractResult {
  rawText: string;
  durationSeconds: number;
}

export async function extractFromVideoURL(url: string, logger?: any): Promise<InstagramExtractResult> {
  return limit(async () => {
    const download = await downloadAudio(url);
    try {
      const combinedText = `${download.title ?? ""} ${download.caption ?? ""}`.trim();
      const detectedLang = detectLanguage(combinedText);

      if (logger && typeof logger.info === "function") {
        logger.info({ detectedLang, url }, "Detected video metadata language for Whisper hint");
      }

      const transcript = await transcribe(download.filePath, detectedLang);

      const parts: string[] = [];
      if (download.title) parts.push(`Título do post: ${download.title}`);
      if (download.caption) parts.push(`Legenda do post:\n${download.caption}`);
      parts.push(`Transcrição do áudio:\n${transcript}`);

      return {
        rawText: parts.join("\n\n"),
        durationSeconds: download.durationSeconds,
      };
    } finally {
      // Always clean up the temp directory — these audio files add up fast.
      await rm(download.cleanupDir, { recursive: true, force: true }).catch(() => {});
    }
  });
}

const VIDEO_HOSTS = new Set([
  "instagram.com",
  "www.instagram.com",
  "tiktok.com",
  "www.tiktok.com",
  "youtube.com",
  "www.youtube.com",
  "youtu.be",
  "m.youtube.com",
]);

export function looksLikeVideoURL(url: URL): boolean {
  return VIDEO_HOSTS.has(url.hostname.toLowerCase());
}
