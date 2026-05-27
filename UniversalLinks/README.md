# Universal Links — Setup

Para abrir `https://vaptvupt.app/recipe?data=…` direto no app instalado (em vez do Safari mostrar a página web), o iOS exige:

1. **Capability "Associated Domains"** marcada nos dois targets (app principal e App Clip).
2. **Arquivo `apple-app-site-association`** hospedado no domínio.

## 1. Xcode — Capability nos targets

### Target VaptVupt (app principal)

1. Project Navigator → projeto `VaptVupt` → target **VaptVupt**.
2. Aba **Signing & Capabilities**.
3. **+ Capability** → **Associated Domains**.
4. Adicionar entrada: `applinks:vaptvupt.app`.

### Target VaptVuptClip

Já tem `appclips:vaptvupt.app` em `VaptVuptClip.entitlements`. Adicione também `applinks:vaptvupt.app` se quiser que o Clip apareça em links HTTPS além do App Clip Card:

1. Signing & Capabilities do target `VaptVuptClip`.
2. **Associated Domains** já existe.
3. Adicionar entrada: `applinks:vaptvupt.app`.

## 2. Hospedar AASA no domínio

Suba o arquivo [`apple-app-site-association`](./apple-app-site-association) deste diretório em:

```
https://vaptvupt.app/.well-known/apple-app-site-association
```

Requisitos do servidor:
- Servido com `Content-Type: application/json`.
- **Sem extensão `.json`** no nome do arquivo (exatamente `apple-app-site-association`).
- Acessível via HTTPS (TLS válido).
- Sem redirect.

**Substitua `TEAMID` pelo seu Team ID** do Apple Developer Program (sem hifens, formato `ABCDE12345`). O bundle identifier completo fica `ABCDE12345.Any.VaptVupt`.

## 3. Validar

Depois de hospedar o AASA:

```bash
curl -I https://vaptvupt.app/.well-known/apple-app-site-association
# Deve retornar 200 com Content-Type: application/json
```

Apple também oferece o **App Search API Validation Tool**: <https://search.developer.apple.com/appsearch-validation-tool/>.

No app, instale uma versão dev no device físico (Universal Links não funcionam de forma confiável no simulador para domínios reais) e abra o link `https://vaptvupt.app/recipe?data=…` no Safari — deve abrir direto no app.

## 4. Sem domínio?

Para desenvolvimento puro sem `vaptvupt.app`, mantenha o esquema custom `vaptvupt://import?data=…` (já implementado em `RecipeShareService`). Universal Links é apenas o melhoramento de "abrir do Safari/iMessage/email" — o restante do fluxo de compartilhamento já funciona.
