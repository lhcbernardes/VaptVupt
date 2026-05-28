//
// High-level parser router. Decides which extraction strategy to use based on
// the URL and falls through to the cheapest path that works.
//
// Strategy order:
//  1. Instagram / TikTok / YouTube → yt-dlp + Whisper (most expensive, only
//     when we know we need it).
//  2. Any other URL → fetch HTML. If JSON-LD Recipe exists, use it (cheapest:
//     no LLM needed for parsing, just structuring).
//  3. Otherwise → use og:tags + main text as raw input for the LLM.
//

import { extractFromVideoURL, looksLikeVideoURL } from "./instagram.js";
import { extractOpenGraph, extractMainText, fetchPage } from "./html.js";
import { findRecipe, renderRecipeAsText } from "./jsonld.js";

export interface ExtractedSource {
  rawText: string;
  sourceHint: string;
}

export async function extractFromURL(url: URL): Promise<ExtractedSource> {
  if (looksLikeVideoURL(url)) {
    const result = await extractFromVideoURL(url.toString());
    return {
      rawText: result.rawText,
      sourceHint: `Vídeo (${url.hostname}) — ${result.durationSeconds}s de áudio.`,
    };
  }

  const page = await fetchPage(url.toString());

  const recipe = findRecipe(page.$);
  if (recipe) {
    return {
      rawText: renderRecipeAsText(recipe),
      sourceHint: `Página com Schema.org Recipe (${url.hostname}).`,
    };
  }

  const og = extractOpenGraph(page.$);
  const body = extractMainText(page.$, 8000);
  const lines: string[] = [];
  if (og.title) lines.push(`Título: ${og.title}`);
  if (og.description) lines.push(`Descrição: ${og.description}`);
  if (og.image) lines.push(`Imagem: ${og.image}`);
  lines.push("\nConteúdo da página:");
  lines.push(body);

  return {
    rawText: lines.join("\n"),
    sourceHint: `Página sem dados estruturados (${url.hostname}).`,
  };
}
