//
// Shared HTML utilities — fetch the page once and extract whatever the
// downstream parsers need (JSON-LD, og:tags, plaintext body).
//

import * as cheerio from "cheerio";

const FETCH_TIMEOUT_MS = 15_000;
const USER_AGENT =
  "Mozilla/5.0 (Macintosh; Intel Mac OS X 14_0) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/130.0.0.0 Safari/537.36";

export interface PageContent {
  html: string;
  $: cheerio.CheerioAPI;
  finalUrl: string;
}

export async function fetchPage(url: string): Promise<PageContent> {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), FETCH_TIMEOUT_MS);
  try {
    const response = await fetch(url, {
      headers: { "user-agent": USER_AGENT, accept: "text/html,application/xhtml+xml" },
      signal: controller.signal,
      redirect: "follow",
    });
    if (!response.ok) {
      throw new Error(`Página retornou ${response.status} ${response.statusText}.`);
    }
    const html = await response.text();
    return { html, $: cheerio.load(html), finalUrl: response.url };
  } finally {
    clearTimeout(timer);
  }
}

export function extractOpenGraph($: cheerio.CheerioAPI): {
  title?: string;
  description?: string;
  image?: string;
} {
  const pick = (prop: string) => $(`meta[property="${prop}"]`).attr("content")?.trim();
  return {
    title: pick("og:title") ?? ($("title").first().text().trim() || undefined),
    description: pick("og:description") ?? $('meta[name="description"]').attr("content")?.trim(),
    image: pick("og:image"),
  };
}

/**
 * Best-effort plaintext body — strips script/style/nav/header/footer and
 * collapses whitespace. Useful as a fallback when there's no JSON-LD.
 */
export function extractMainText($: cheerio.CheerioAPI, maxChars = 8000): string {
  const clone = $.root().clone();
  clone.find("script, style, nav, header, footer, aside, form, iframe").remove();
  const text = clone.text().replace(/\s+/g, " ").trim();
  return text.slice(0, maxChars);
}
