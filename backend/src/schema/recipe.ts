//
// Recipe schema — shared between Zod validation, Anthropic structured output,
// and the wire format the iOS app deserializes.
//
// The shape matches `VaptVupt/Domain/Models/Recipe.swift` so the client can
// decode the response with the existing Codable struct.
//

import { z } from "zod";

export const IngredientUnitSchema = z.enum([
  "g",
  "kg",
  "ml",
  "l",
  "xícara",
  "colher",
  "colher de chá",
  "unidade",
  "pitada",
  "a gosto",
]);

export const IngredientSchema = z.object({
  name: z.string(),
  quantity: z.number(),
  unit: IngredientUnitSchema,
});

export const StepSchema = z.object({
  sequence: z.number().int().positive(),
  instruction: z.string(),
});

export const DifficultySchema = z.enum(["Fácil", "Médio", "Difícil"]);

export const SubcategorySchema = z.enum([
  "Café da Manhã",
  "Almoço",
  "Lanche",
  "Jantar",
  "Low Carb",
  "Proteico",
  "Sem Açúcar",
  "Com Álcool",
  "Sem Álcool",
]);

export const DietaryRestrictionSchema = z.enum([
  "Vegetariano",
  "Vegano",
  "Sem Glúten",
  "Sem Lactose",
  "Sem Açúcar",
]);

export const RecipeSchema = z.object({
  title: z.string(),
  description: z.string().nullable().optional(),
  prepTime: z.number().int().positive(),
  servings: z.number().int().positive(),
  imageURL: z.string().url().nullable().optional(),
  subcategories: z.array(SubcategorySchema),
  difficulty: DifficultySchema,
  ingredients: z.array(IngredientSchema).min(1),
  steps: z.array(StepSchema).min(1),
  dietaryRestrictions: z.array(DietaryRestrictionSchema),
});

export type Recipe = z.infer<typeof RecipeSchema>;

/**
 * Plain JSON Schema mirroring the Zod shape — passed to Anthropic via
 * `output_config.format` for guaranteed structured output. Kept in sync
 * with `RecipeSchema` by inspection.
 */
export const RECIPE_JSON_SCHEMA = {
  type: "object",
  additionalProperties: false,
  required: [
    "title",
    "prepTime",
    "servings",
    "subcategories",
    "difficulty",
    "ingredients",
    "steps",
    "dietaryRestrictions",
  ],
  properties: {
    title: { type: "string" },
    description: { type: "string" },
    prepTime: { type: "integer", description: "Minutos totais." },
    servings: { type: "integer" },
    imageURL: { type: "string", format: "uri" },
    subcategories: {
      type: "array",
      items: { enum: SubcategorySchema.options },
    },
    difficulty: { enum: DifficultySchema.options },
    ingredients: {
      type: "array",
      minItems: 1,
      items: {
        type: "object",
        additionalProperties: false,
        required: ["name", "quantity", "unit"],
        properties: {
          name: { type: "string" },
          quantity: { type: "number" },
          unit: { enum: IngredientUnitSchema.options },
        },
      },
    },
    steps: {
      type: "array",
      minItems: 1,
      items: {
        type: "object",
        additionalProperties: false,
        required: ["sequence", "instruction"],
        properties: {
          sequence: { type: "integer" },
          instruction: { type: "string" },
        },
      },
    },
    dietaryRestrictions: {
      type: "array",
      items: { enum: DietaryRestrictionSchema.options },
    },
  },
} as const;
