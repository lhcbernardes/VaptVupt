//
// Schema.org Recipe extractor — when a blog publishes structured data (most
// big recipe sites do: Allrecipes, NYT Cooking, Tudo Gostoso, AnaMariaBraga
// etc.), we get the entire recipe without needing the LLM.
//
// We extract every JSON-LD island on the page and look for `@type=Recipe`,
// including nested `@graph` arrays.
//

import type { CheerioAPI } from "cheerio";

export interface JsonLdRecipe {
  name?: string;
  description?: string;
  image?: string | string[] | { url?: string };
  recipeIngredient?: string[];
  recipeInstructions?: unknown;
  recipeYield?: string | string[] | number;
  totalTime?: string;
  cookTime?: string;
  prepTime?: string;
  recipeCategory?: string | string[];
  suitableForDiet?: string | string[];
}

export function findRecipe($: CheerioAPI): JsonLdRecipe | null {
  const scripts = $('script[type="application/ld+json"]').toArray();
  for (const script of scripts) {
    const raw = $(script).contents().text().trim();
    if (!raw) continue;
    let parsed: unknown;
    try {
      parsed = JSON.parse(raw);
    } catch {
      continue;
    }
    const recipe = findRecipeInNode(parsed);
    if (recipe) return recipe;
  }
  return null;
}

function findRecipeInNode(node: unknown): JsonLdRecipe | null {
  if (!node || typeof node !== "object") return null;

  if (Array.isArray(node)) {
    for (const item of node) {
      const found = findRecipeInNode(item);
      if (found) return found;
    }
    return null;
  }

  const obj = node as Record<string, unknown>;
  const type = obj["@type"];
  if (type === "Recipe" || (Array.isArray(type) && type.includes("Recipe"))) {
    return obj as JsonLdRecipe;
  }

  if (Array.isArray(obj["@graph"])) {
    return findRecipeInNode(obj["@graph"]);
  }

  return null;
}

/**
 * Renders a JSON-LD Recipe into a flat text blob suitable for handing to the
 * LLM. We could parse it ourselves, but Schema.org is loose enough (durations
 * in ISO 8601, yields as either number or string, instructions as a string,
 * an array, or an array of HowToStep objects) that letting the LLM normalize
 * is more reliable than 200 lines of edge-case branches.
 */
export function renderRecipeAsText(recipe: JsonLdRecipe): string {
  const lines: string[] = [];
  if (recipe.name) lines.push(`Título: ${recipe.name}`);
  if (recipe.description) lines.push(`\nDescrição: ${recipe.description}`);
  if (recipe.recipeYield) lines.push(`\nRendimento: ${stringify(recipe.recipeYield)}`);
  if (recipe.totalTime) lines.push(`Tempo total: ${recipe.totalTime}`);
  else if (recipe.cookTime) lines.push(`Tempo de cozimento: ${recipe.cookTime}`);
  if (recipe.prepTime) lines.push(`Tempo de preparo: ${recipe.prepTime}`);

  if (recipe.recipeIngredient?.length) {
    lines.push("\nIngredientes:");
    for (const ing of recipe.recipeIngredient) lines.push(`- ${ing}`);
  }

  const instructions = normalizeInstructions(recipe.recipeInstructions);
  if (instructions.length) {
    lines.push("\nModo de preparo:");
    instructions.forEach((step, i) => lines.push(`${i + 1}. ${step}`));
  }

  if (recipe.recipeCategory) lines.push(`\nCategoria: ${stringify(recipe.recipeCategory)}`);
  if (recipe.suitableForDiet) lines.push(`Dieta: ${stringify(recipe.suitableForDiet)}`);

  return lines.join("\n");
}

function stringify(value: unknown): string {
  if (Array.isArray(value)) return value.map((v) => stringify(v)).join(", ");
  if (value && typeof value === "object") return JSON.stringify(value);
  return String(value);
}

function normalizeInstructions(input: unknown): string[] {
  if (!input) return [];
  if (typeof input === "string") {
    return input
      .split(/(?:\r?\n|\.\s+)/)
      .map((s) => s.trim())
      .filter((s) => s.length > 4);
  }
  if (Array.isArray(input)) {
    const out: string[] = [];
    for (const item of input) {
      if (typeof item === "string") out.push(item);
      else if (item && typeof item === "object") {
        const obj = item as Record<string, unknown>;
        if (typeof obj.text === "string") out.push(obj.text);
        else if (typeof obj.name === "string") out.push(obj.name);
        else if (Array.isArray(obj.itemListElement)) {
          out.push(...normalizeInstructions(obj.itemListElement));
        }
      }
    }
    return out;
  }
  return [];
}

/** Pulls the best image URL out of the polymorphic `image` field. */
export function pickImage(recipe: JsonLdRecipe): string | undefined {
  const img = recipe.image;
  if (!img) return undefined;
  if (typeof img === "string") return img;
  if (Array.isArray(img)) return typeof img[0] === "string" ? img[0] : undefined;
  return img.url;
}
