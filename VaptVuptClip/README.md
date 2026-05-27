# VaptVuptClip

Arquivos prontos para um target **App Clip** que ainda não existe no projeto Xcode. **NÃO compilam** no estado atual — aguardam o target ser criado pelo Xcode.

App Clips são versões "lite" do app principal (até 15 MB descomprimido) que rodam sem instalação completa. Para o VaptVupt, servem para abrir receitas compartilhadas em quem não tem o app.

## Como ativar

### 1. Criar o target no Xcode

1. Abra `VaptVupt.xcodeproj`.
2. **File → New → Target… → iOS → App Clip**.
3. Product Name: `VaptVuptClip`.
4. Containing App: **VaptVupt**.
5. Finish → quando perguntar "Activate scheme?", aceite.

O Xcode vai gerar um `VaptVuptClipApp.swift` placeholder — **apague**.

### 2. Mover os arquivos para o novo target

Arraste estes arquivos para dentro do grupo `VaptVuptClip` criado pelo Xcode:

- `VaptVuptClipApp.swift`
- `RecipeClipView.swift`
- `Info.plist` (sobrescreva o gerado)
- `VaptVuptClip.entitlements` (sobrescreva o gerado)

Marque **apenas o target VaptVuptClip** em Target Membership.

### 3. Compartilhar arquivos com o target principal

Os arquivos abaixo já existem no target principal. **Marque também o target `VaptVuptClip`** em File Inspector → Target Membership de cada um:

| Arquivo | Onde |
|---|---|
| `Recipe.swift` | `Domain/Models/` |
| `RecipeCategory.swift` | `Domain/Models/` |
| `Ingredient.swift` | `Domain/Models/` |
| `Step.swift` | `Domain/Models/` |
| `DietaryRestriction.swift` | `Domain/Models/` |
| `RecipeShareService.swift` | `Domain/Services/` |
| `Theme.swift` | `Presentation/Theme/` |
| `RemoteImage.swift` | `Presentation/Components/` |
| `TagPill.swift` | `Presentation/Components/` |

### 4. Universal Link (opcional, para produção)

Para que o App Clip seja invocado automaticamente ao tocar em `https://vaptvupt.app/recipe?data=…` no Safari:

1. **Signing & Capabilities** do target `VaptVuptClip` → adicione **Associated Domains**.
2. Adicione: `appclips:vaptvupt.app` (já incluído no `.entitlements`).
3. Hospede `apple-app-site-association` em `https://vaptvupt.app/.well-known/`:
   ```json
   {
     "applinks": {
       "details": [
         { "appIDs": ["TEAMID.Any.VaptVupt.Clip"], "components": [{ "/": "/recipe*" }] }
       ]
     },
     "appclips": { "apps": ["TEAMID.Any.VaptVupt.Clip"] }
   }
   ```
4. No App Store Connect, gere App Clip Codes (QR Codes específicos) para distribuir.

### 5. Testando localmente (sem domínio)

No Xcode, **Product → Scheme → Edit Scheme…** → escolha o esquema **VaptVuptClip** → **Run** → **Arguments** → adicione em **_XCAppClipURL** um URL como:

```
vaptvupt://import?data=eyJ2IjoxLCJwYXlsb2FkIjp7...
```

(Cole um link real que você gerou compartilhando uma receita do app completo.)

Rodando o esquema do Clip vai abrir direto no `RecipeClipView` com a receita decodificada.

## Limites do App Clip

- 15 MB descomprimido. Por isso o Clip não inclui Modo Cozinha, favoritos, despensa nem upload.
- Sem persistência longa: o iOS pode descartar o Clip a qualquer momento.
- Sem `UNUserNotificationCenter` — para notificar, é só com o app completo instalado.
- O botão "Abrir no app completo" tenta `UIApplication.shared.open(vaptvupt://…)`. Se o app principal não estiver instalado, o iOS oferece instalar via App Clip Card nativo.
