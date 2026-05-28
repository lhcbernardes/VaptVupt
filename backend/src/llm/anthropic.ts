//
// Anthropic Claude client — turns raw recipe text (caption, transcript, JSON-LD
// dump, or scraped HTML body) into a `Recipe` JSON.
//
// Decisions:
//  • Model: Claude Opus 4.7 (`claude-opus-4-7`).
//  • Adaptive thinking — let Claude decide how much to reason per request.
//  • effort: "high" — recipe structuring needs accuracy; cost is OK.
//  • Structured output via `output_config.format` JSON schema — guarantees
//    the response is valid `Recipe` JSON, no manual parsing fallback needed.
//  • System prompt cached (`cache_control: ephemeral`) — every request shares
//    the same instructions + schema reference, so the prefix is reused.
//

import Anthropic from "@anthropic-ai/sdk";
import { RECIPE_JSON_SCHEMA, RecipeSchema, type Recipe } from "../schema/recipe.js";

const client = new Anthropic({ apiKey: process.env.ANTHROPIC_API_KEY });

const SYSTEM_PROMPT = `Você é um especialista em transformar receitas em texto cru (legendas, transcrições, blogs) em JSON estruturado pro app VaptVupt.

Regras:
1. Sempre devolva uma única receita estruturada conforme o schema.
2. Idioma da saída: português brasileiro.
3. Ingredientes: extraia quantidade e unidade quando possível. Quando o texto disser "a gosto", use unit="a gosto" e quantity=1.
4. Tempo de preparo: estime em minutos quando não estiver explícito (ex.: receita simples = 15, prato com forno = 45).
5. Porções: padrão 2 se não declarado.
6. Subcategorias: escolha as mais coerentes do enum (1-3 itens). Receitas doces/lanches = "Lanche", refeições principais = "Almoço" ou "Jantar".
7. Restrições alimentares: marque APENAS quando claramente apropriado (ex.: receita sem carne nem peixe = "Vegetariano"; sem leite/derivados = "Sem Lactose").
8. Difficulty: "Fácil" se ≤ 5 ingredientes ou ≤ 20 min, "Médio" se moderada, "Difícil" se mais elaborada (forno + várias etapas).
9. Passos: numere sequencialmente começando em 1, mantenha instruções curtas e acionáveis.
10. NÃO invente ingredientes que não estão no texto. Se faltar informação, prefira ser conservador.`;

export async function structureRecipe(
  rawText: string,
  sourceHint?: string,
  logger?: any,
): Promise<Recipe> {
  const userMessage = sourceHint
    ? `Fonte: ${sourceHint}\n\nTexto bruto da receita:\n\n${rawText}`
    : `Texto bruto da receita:\n\n${rawText}`;

  const response = await client.messages.create({
    model: "claude-opus-4-7",
    max_tokens: 4096,
    thinking: { type: "adaptive" },
    output_config: {
      effort: "high",
      format: {
        type: "json_schema",
        schema: RECIPE_JSON_SCHEMA,
      },
    },
    system: [
      {
        type: "text",
        text: SYSTEM_PROMPT,
        cache_control: { type: "ephemeral" },
      },
    ],
    messages: [{ role: "user", content: userMessage }],
  } as any);

  logUsage(response.usage, logger);

  // With `output_config.format`, the first text block is guaranteed JSON.
  const textBlock = response.content.find((b) => b.type === "text");
  if (!textBlock || textBlock.type !== "text") {
    throw new Error("LLM did not return a text block with the structured recipe.");
  }

  const json = JSON.parse(textBlock.text);

  // Re-validate via Zod — catches any drift between schema and runtime payload.
  return RecipeSchema.parse(json);
}

/** Telemetry: log cache hit ratio so we can verify the prompt prefix is being reused. */
export function logUsage(usage: Anthropic.Messages.Usage | undefined, logger?: any): void {
  if (!usage) return;
  const totalInput =
    usage.input_tokens + (usage.cache_creation_input_tokens ?? 0) + (usage.cache_read_input_tokens ?? 0);
  const cachePct = totalInput > 0 ? Math.round(((usage.cache_read_input_tokens ?? 0) / totalInput) * 100) : 0;

  const msg = `[anthropic] in=${usage.input_tokens} cache_write=${usage.cache_creation_input_tokens ?? 0} cache_read=${usage.cache_read_input_tokens ?? 0} out=${usage.output_tokens} (cache_hit=${cachePct}%)`;

  if (logger && typeof logger.info === "function") {
    logger.info(
      {
        telemetry: {
          inputTokens: usage.input_tokens,
          cacheWriteTokens: usage.cache_creation_input_tokens ?? 0,
          cacheReadTokens: usage.cache_read_input_tokens ?? 0,
          outputTokens: usage.output_tokens,
          cacheHitPercentage: cachePct,
        },
      },
      msg,
    );
  } else {
    console.log(msg);
  }
}
