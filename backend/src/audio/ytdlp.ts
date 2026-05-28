//
// Thin wrapper around the `yt-dlp` CLI. We avoid the npm bindings because
// they're flaky and lag behind upstream — pinning a binary is simpler and
// keeps the Docker image deterministic.
//
// Downloads the audio track only (mp3, 64kbps mono) — Whisper happily handles
// low bitrate and we keep the upload size small.
//

import { spawn } from "node:child_process";
import { mkdtemp, readdir } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";

const MAX_DURATION_SECONDS = 600; // hard cap — refuse 10+ minute videos
const YTDLP_BIN = process.env.YTDLP_BIN ?? "yt-dlp";

export interface AudioDownloadResult {
  filePath: string;
  cleanupDir: string;
  caption?: string;
  title?: string;
  durationSeconds: number;
}

/**
 * Downloads the audio track and best-available caption metadata from a
 * supported URL (Instagram, TikTok, YouTube). Throws if the duration exceeds
 * `MAX_DURATION_SECONDS` — long videos balloon Whisper costs.
 */
export async function downloadAudio(url: string): Promise<AudioDownloadResult> {
  const cleanupDir = await mkdtemp(join(tmpdir(), "vaptvupt-ytdlp-"));
  const outputTemplate = join(cleanupDir, "audio.%(ext)s");

  await run(YTDLP_BIN, [
    "--no-playlist",
    "--no-warnings",
    "--no-progress",
    "--max-filesize", "50M",
    "--match-filter", `duration <= ${MAX_DURATION_SECONDS}`,
    "--extract-audio",
    "--audio-format", "mp3",
    "--audio-quality", "9",
    "--postprocessor-args", "-ac 1 -ar 16000 -b:a 64k",
    "--write-info-json",
    "--no-write-thumbnail",
    "-o", outputTemplate,
    url,
  ]);

  // yt-dlp may emit any of audio.mp3 / audio.m4a / audio.opus depending on
  // the source; pick whichever showed up.
  const files = await readdir(cleanupDir);
  const audio = files.find((f) => f.startsWith("audio.") && !f.endsWith(".json"));
  const infoFile = files.find((f) => f.endsWith(".info.json"));
  if (!audio) {
    throw new Error("yt-dlp finished but no audio file was produced.");
  }

  let caption: string | undefined;
  let title: string | undefined;
  let durationSeconds = 0;
  if (infoFile) {
    const fs = await import("node:fs/promises");
    const raw = await fs.readFile(join(cleanupDir, infoFile), "utf8");
    const meta = JSON.parse(raw) as { description?: string; title?: string; duration?: number };
    caption = meta.description?.trim();
    title = meta.title?.trim();
    durationSeconds = meta.duration ?? 0;
  }

  return {
    filePath: join(cleanupDir, audio),
    cleanupDir,
    caption,
    title,
    durationSeconds,
  };
}

function run(cmd: string, args: string[]): Promise<void> {
  return new Promise((resolve, reject) => {
    const proc = spawn(cmd, args, { stdio: ["ignore", "pipe", "pipe"] });
    let stderr = "";
    proc.stderr.on("data", (chunk) => { stderr += chunk.toString(); });
    proc.on("error", reject);
    proc.on("close", (code) => {
      if (code === 0) {
        resolve();
      } else {
        reject(new Error(`yt-dlp exited with code ${code}: ${stderr.trim()}`));
      }
    });
  });
}
