# VaptVupt Recipe Parser — Backend

Node + TypeScript service que recebe uma URL (blog, Instagram, TikTok, YouTube Shorts) e devolve uma `Recipe` JSON estruturada pronta pro app iOS consumir.

## Pipeline

```
POST /parse-url { url }
     │
     ▼
┌────────────────────────────────────────────────┐
│ 1. URL é Instagram / TikTok / YouTube?         │
│    → yt-dlp baixa áudio + captura caption      │
│    → Whisper (OpenAI) transcreve áudio         │
│    → texto bruto = caption + transcript        │
│                                                │
│ 2. URL de blog com JSON-LD Recipe?             │
│    → cheerio extrai Schema.org direto          │
│    → texto bruto = receita estruturada         │
│                                                │
│ 3. URL de blog sem JSON-LD?                    │
│    → fallback: og:tags + corpo da página       │
│                                                │
│ ─────────────────────────────────────────────► │
│ Claude Opus 4.7 estrutura em Recipe JSON       │
│   • adaptive thinking + effort: high           │
│   • output_config.format (JSON schema)         │
│   • prompt caching no system prompt            │
│                                                │
│ Cache LRU em memória (24h TTL, 500 entradas)   │
└────────────────────────────────────────────────┘
     │
     ▼
{ recipe: Recipe, cached: boolean }
```

## Endpoints

### `POST /parse-url`

**Body:** `{ "url": "https://www.instagram.com/reel/..." }`

**200:** `{ "recipe": Recipe, "cached": boolean }` — schema em `src/schema/recipe.ts`.

**422:** `{ "error": "video_unavailable" | "structuring_failed" | "page_unavailable" | "parse_failed", "message": string }`

**400:** body inválido.

**401:** Bearer token ausente/inválido (apenas se `APP_API_KEY` estiver setado).

### `GET /health`

`200 { status: "ok" }` — pra Railway/Fly liveness probes.

## Configuração

Copie `.env.example` pra `.env` e preencha:

| Variável | Obrigatório | Descrição |
|---|---|---|
| `ANTHROPIC_API_KEY` | sim | Claude para estruturação. Crie em https://console.anthropic.com |
| `OPENAI_API_KEY` | sim | Whisper API. Crie em https://platform.openai.com |
| `APP_API_KEY` | recomendado em prod | Bearer token que o app iOS envia. Se vazio, qualquer cliente pode chamar. |
| `PORT` | não (default 3000) | Porta de escuta |
| `LOG_LEVEL` | não (default info) | `trace`/`debug`/`info`/`warn`/`error` |
| `YTDLP_BIN` | não (default `yt-dlp`) | Path do binário yt-dlp |

## Rodando localmente

```bash
cd backend
npm install

# yt-dlp e ffmpeg precisam estar no PATH local:
brew install yt-dlp ffmpeg

cp .env.example .env  # preencha as chaves
npm run dev
```

Teste:

```bash
curl -X POST http://localhost:3000/parse-url \
  -H "Content-Type: application/json" \
  -d '{"url": "https://www.tudogostoso.com.br/receita/123-bolo-de-cenoura.html"}'
```

## Deploy (Railway)

1. **Crie um projeto** no Railway: https://railway.app/new
2. Conecte o repositório `lhcbernardes/VaptVupt`.
3. **Root Directory**: `backend`.
4. Railway detecta o `Dockerfile` automaticamente.
5. **Variables**: adicione `ANTHROPIC_API_KEY`, `OPENAI_API_KEY`, `APP_API_KEY`.
6. Deploy → Railway expõe `https://<seu-projeto>.up.railway.app`.
7. Configure custom domain se quiser (`api.vaptvupt.app`).

## Deploy (Fly.io)

```bash
fly launch --copy-config --no-deploy
# Edite fly.toml se necessário
fly secrets set ANTHROPIC_API_KEY=... OPENAI_API_KEY=... APP_API_KEY=...
fly deploy
```

## Custos aproximados

Por receita parseada:

| Fonte | Custo estimado |
|---|---|
| Blog com JSON-LD | ~$0.005 (só LLM) |
| Blog sem JSON-LD | ~$0.01 (LLM + HTML body maior) |
| Instagram / TikTok reel (60s) | ~$0.012 (Whisper $0.006 + Claude $0.006) |
| YouTube Short (longo, 5 min) | ~$0.04 (Whisper $0.03 + Claude $0.01) |

Prompt caching no system prompt corta o custo das chamadas Claude subsequentes em ~90%. Cache LRU local zera o custo de re-parses da mesma URL dentro de 24h.

## Limitações

- **yt-dlp** depende de cookies da plataforma e às vezes quebra com mudanças no Instagram. Mantenha o binário atualizado (`pip3 install -U yt-dlp`).
- **Whisper** transcreve português brasileiro como hint, mas funciona com qualquer idioma se a hint estiver errada.
- Vídeos > 10 min são rejeitados (`MAX_DURATION_SECONDS` em `src/audio/ytdlp.ts`).
- Sem persistência: cache vive na memória do processo. Reinício zera o cache. Trocar para Redis/Upstash é uma alteração de ~20 linhas em `src/cache/`.
