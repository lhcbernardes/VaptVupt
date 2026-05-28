//
// Stopword-based structural language detector. Fast, zero-dependency,
// and highly effective for classifying cooking post captions.
//

export function detectLanguage(text: string | undefined): string {
  if (!text) return "pt"; // default to pt
  const lower = text.toLowerCase();

  // Count frequency of common language-specific stopwords
  const ptWords = [" receita ", " de ", " do ", " da ", " com ", " para ", " em "];
  const enWords = [" recipe ", " of ", " in ", " with ", " for ", " and ", " the "];
  const esWords = [" receta ", " y ", " el ", " la ", " con ", " para ", " en "];

  let ptCount = 0;
  let enCount = 0;
  let esCount = 0;

  for (const w of ptWords) {
    if (lower.includes(w)) ptCount++;
  }
  for (const w of enWords) {
    if (lower.includes(w)) enCount++;
  }
  for (const w of esWords) {
    if (lower.includes(w)) esCount++;
  }

  if (enCount > ptCount && enCount > esCount) return "en";
  if (esCount > ptCount && esCount > enCount) return "es";
  return "pt"; // default/fallback
}
