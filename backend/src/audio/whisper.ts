//
// OpenAI Whisper API wrapper. Returns the transcribed text for a local audio
// file. We always send pt-BR as hint — Instagram cooking reels are mostly
// Brazilian; the cost of being slightly wrong on language hint is negligible.
//

import { createReadStream } from "node:fs";
import OpenAI from "openai";

const client = new OpenAI({ apiKey: process.env.OPENAI_API_KEY });

export async function transcribe(filePath: string, languageHint = "pt"): Promise<string> {
  const result = await client.audio.transcriptions.create({
    file: createReadStream(filePath),
    model: "whisper-1",
    language: languageHint,
    response_format: "text",
  });
  // `text` response format already returns a plain string.
  return (typeof result === "string" ? result : result.text).trim();
}
