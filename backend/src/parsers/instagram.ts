//
// Instagram (and TikTok / YouTube Shorts) parser. Downloads the audio with
// yt-dlp, runs OpenAI Whisper, and combines the transcript with the post's
// public caption. The result is a single text blob ready for the LLM.
//

import { rm } from "node:fs/promises";
import { downloadAudio } from "../audio/ytdlp.js";
import { transcribe } from "../audio/whisper.js";

export interface InstagramExtractResult {
  rawText: string;
  durationSeconds: number;
}

export async function extractFromVideoURL(url: string): Promise<InstagramExtractResult> {
  const download = await downloadAudio(url);
  try {
    const transcript = await transcribe(download.filePath);

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
