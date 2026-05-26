# VaptVupt

Aplicativo iOS de receitas culinárias em **SwiftUI**, com Modo Cozinha guiado, timer integrado, despensa inteligente e upload assistido por IA. Construído com arquitetura limpa (Domain / Data / Presentation), `@Observable`, **SwiftData** para persistência do histórico e `UserNotifications` para alertas locais do timer.

---

## Sumário

- [Funcionalidades](#funcionalidades)
- [Arquitetura](#arquitetura)
- [Stack & Frameworks](#stack--frameworks)
- [Estrutura de pastas](#estrutura-de-pastas)
- [Modelo de domínio](#modelo-de-domínio)
- [Serviços](#serviços)
- [Telas](#telas)
- [Persistência](#persistência)
- [Design System](#design-system)
- [Requisitos](#requisitos)
- [Como rodar](#como-rodar)
- [Testes](#testes)
- [Roadmap](#roadmap)
- [Licença](#licença)

---

## Funcionalidades

- **Dashboard** com saudação dinâmica, "Receita do Dia" determinística, cards de categorias (Refeições, Fit, Bebidas), seção **"Pronto pra fazer"** (cruza despensa × ingredientes) e atalho rápido para favoritos.
- **Catálogo por categoria** com filtros de tempo de preparo (`PrepTimeFilter`) e subcategorias.
- **Detalhe de receita** com seletor de porções dinâmico (recalcula quantidades), lista de ingredientes, passos numerados e botão *Iniciar Modo Cozinha*.
- **Modo Cozinha** em `TabView` paginado por passo, com:
  - **Detecção automática de tempo** nas instruções (regex em "minutos"/"horas") → propõe iniciar timer.
  - **Timer regressivo reativo** (`CookingTimerController`), com play/pause, progresso e formatação `mm:ss`.
  - **Notificação local agendada** para tocar mesmo com o app em background/tela bloqueada (`interruptionLevel = .timeSensitive`).
  - **Registro do preparo** em SwiftData (`CookedRecipeEntry`) ao concluir a receita.
- **Despensa Inteligente** (`PantryStore`):
  - Adicionar / remover ingredientes com sugestões âncora ("Ovo", "Leite", "Arroz", …).
  - **Match fuzzy bidirecional** ("ovo" ↔ "ovos", "leite" ↔ "leite integral").
  - Score por receita (`PantryMatch`) e filtro `cookableRecipes(minPercentage:)`.
- **Upload Inteligente** via `RecipeAIService` (mock LLM):
  - Quatro fontes: foto (OCR), voz, link, texto colado.
  - Heurísticas de parsing (categorias, tempo, porções, ingredientes, passos) que simulam o JSON de uma LLM real.
- **Favoritos** persistidos (`FavoritesStore` em `UserDefaults`).
- **Lista de compras** derivada de receitas/despensa.
- **Ajustes**: aparência (claro/escuro/sistema via `AppearanceMode`), permissões de notificação e histórico de preparos.

---

## Arquitetura

Inspirada em **Clean Architecture** com três camadas:

```
Presentation  →  Domain  ←  Data
   (Views,        (Models,    (Mocks,
    ViewModels)    Services)   Repositories)
```

- **Domain**: `Recipe`, `Ingredient`, `Step`, `RecipeCategory`, `PantryItem`, `CookedRecipeEntry`, `PrepTimeFilter`, `AppearanceMode`. Serviços de domínio (`FavoritesStore`, `PantryStore`, `NotificationService`, `CookingTimerController`, `RecipeAIService`).
- **Presentation**: cada feature em sua pasta (`Dashboard/`, `RecipeDetail/`, `Pantry/`, `Upload/`, `Settings/`, `ShoppingList/`, `CategoryRecipes/`) seguindo o par `View + ViewModel`.
- **Data**: hoje apenas `MockRecipes` (semente local). Camada pronta para acoplar Firebase, Supabase ou um cliente HTTP de LLM real.

Os stores globais (`DashboardViewModel`, `FavoritesStore`, `NotificationService`, `PantryStore`) são instanciados em `VaptVuptApp` e injetados via `.environment(...)`. O `ModelContainer` do **SwiftData** é único para a sessão e dedicado ao histórico de preparos.

---

## Stack & Frameworks

| Categoria | Tecnologia |
|---|---|
| UI | SwiftUI (iOS 17+) |
| Estado | `@Observable` (Observation framework), `@State`, `@Bindable`, `@Environment` |
| Persistência local | SwiftData (`CookedRecipeEntry`) + `UserDefaults` (favoritos, despensa, aparência) |
| Notificações | `UserNotifications` (`UNUserNotificationCenter`) |
| Concorrência | `async/await` (sem Combine, conforme padrão do projeto) |
| Testes | Swift Testing (unit) + XCUIAutomation (UI) |

---

## Estrutura de pastas

```
VaptVupt/
├── VaptVuptApp.swift              # Entry-point, ModelContainer, env stores
├── ContentView.swift              # RootTabView (Início / Adicionar / Ajustes)
├── Assets.xcassets
├── Data/
│   └── Mock/
│       └── MockRecipes.swift      # Semente de receitas locais
├── Domain/
│   ├── Models/
│   │   ├── Recipe.swift           # Recipe + RecipeDifficulty
│   │   ├── RecipeCategory.swift   # Groups + Subcategories
│   │   ├── Ingredient.swift       # Ingrediente + IngredientUnit
│   │   ├── Step.swift             # Passo de preparo
│   │   ├── PantryItem.swift
│   │   ├── CookedRecipeEntry.swift # @Model SwiftData
│   │   ├── PrepTimeFilter.swift
│   │   └── AppearanceMode.swift
│   └── Services/
│       ├── FavoritesStore.swift
│       ├── PantryStore.swift
│       ├── NotificationService.swift
│       ├── CookingTimerController.swift
│       └── RecipeAIService.swift  # Mock LLM
└── Presentation/
    ├── Dashboard/
    ├── CategoryRecipes/
    ├── RecipeDetail/              # RecipeDetailView + CookingModeView
    ├── Pantry/
    ├── Upload/
    ├── ShoppingList/
    ├── Settings/
    ├── Components/                # CategoryCard, RecipeCard, TagPill, RemoteImage
    └── Theme/
        └── Theme.swift            # Tokens (cores, tipografia, espaçamentos)
```

---

## Modelo de domínio

### `Recipe`

```swift
struct Recipe: Identifiable, Codable, Hashable {
    var id: UUID
    var title: String
    var description: String?
    var prepTime: Int            // minutos
    var servings: Int
    var imageURL: URL?
    var subcategories: [RecipeSubcategory]
    var difficulty: RecipeDifficulty   // .easy / .medium / .hard
    var ingredients: [Ingredient]
    var steps: [Step]
}
```

### Categorias

Três grupos principais (`RecipeCategoryGroup`): **Refeições**, **Espaço Fit** e **Drinks & Bebidas** — cada um com cor de destaque (âmbar / verde sálvia / rosa berry) e ícone SF Symbols. Subcategorias granulares (`RecipeSubcategory`) classificam de forma fina (ex.: `breakfast`, `lowCarb`, `nonAlcoholic`).

### Despensa

`PantryItem` armazena nome normalizado. O `PantryStore` calcula `PantryMatch` para cada receita: `matchedCount`, `totalCount`, `percentage`, `canCookNow` e um `label` amigável ("Tem 4/5", "Tem tudo!").

### Histórico

`CookedRecipeEntry` é o único `@Model` SwiftData: registra título, data e referência da receita preparada.

---

## Serviços

### `RecipeAIService` (mock LLM)

```swift
func parseRecipeFromText(_ text: String, source: InputSource = .text) async -> Recipe?
```

Simula latência de ~1.2s e aplica heurísticas (regex + dicionário de termos) para inferir título, tempo de preparo, porções, subcategorias, ingredientes e passos a partir de texto bruto. Substituível em produção por um cliente HTTP que serializa para JSON estruturado.

### `CookingTimerController`

- **Detecção** via regex: `detectMinutes(in:)` extrai minutos/horas mencionados nas instruções.
- **Reatividade** com `@Observable`: `formatted`, `progress` e `isRunning` atualizam a UI sem `Combine`.
- **Integração** com `NotificationService` para agendar/cancelar a notificação ao iniciar/pausar/cancelar.

### `NotificationService`

Encapsula `UNUserNotificationCenter`. Garante que o "ding" final do timer dispare mesmo com app fechado/tela bloqueada (`interruptionLevel = .timeSensitive`). Identificador único — só existe um timer ativo por vez.

### `FavoritesStore` / `PantryStore`

Persistência leve em `UserDefaults` com chaves versionadas (`snapchef.favorites.v1`, `snapchef.pantry.v1`). Migração para SwiftData/backend remoto está prevista no roadmap.

---

## Telas

| Tela | Responsabilidade |
|---|---|
| **DashboardView** | Saudação, Receita do Dia, categorias, "Pronto pra fazer", favoritos. |
| **CategoryRecipesView** | Grid filtrável por tempo de preparo e subcategoria. |
| **RecipeDetailView** | Hero, seletor de porções, ingredientes, passos, CTA Modo Cozinha. |
| **CookingModeView** | `TabView` paginado, timer reativo, notificação, gravação em SwiftData. |
| **PantryView** | CRUD da despensa com sugestões âncora. |
| **UploadRecipeView** | Quatro fontes (foto / voz / link / texto) integradas ao `RecipeAIService`. |
| **ShoppingListView** | Lista de compras derivada de receitas selecionadas × despensa. |
| **SettingsView** | Aparência, permissões, histórico de preparos. |

A aba **"Adicionar"** do `RootTabView` é um truque visual: ao ser selecionada, abre o Upload como `.sheet` e retorna o foco para *Início*, mantendo a inicialização leve.

---

## Persistência

- **SwiftData** (`ModelContainer(for: CookedRecipeEntry.self)`): histórico de preparos. Inicialização é fatal — o app não funciona consistentemente sem ela.
- **UserDefaults**: favoritos, itens da despensa e aparência (`@AppStorage("snapchef.appearance")`).

---

## Design System

Tokens centralizados em `Presentation/Theme/Theme.swift`:

- **Cores**: paleta neutra com acento âmbar (cor principal), e cores específicas por categoria (âmbar / verde sálvia / rosa berry).
- **Tipografia**: estilos derivados do sistema iOS, com pesos calibrados para hierarquia.
- **Componentes reutilizáveis**: `CategoryCard`, `RecipeCard`, `TagPill`, `RemoteImage` (carregamento assíncrono de imagens com fallback).

---

## Requisitos

- **Xcode 16+**
- **iOS 17+** (uso de `@Observable`, `.sensoryFeedback`, novas APIs de SwiftData)
- **Swift 5.9+**
- Conta de desenvolvedor Apple (não obrigatório para rodar no simulador)

---

## Como rodar

```bash
git clone https://github.com/lhcbernardes/VaptVupt.git
cd VaptVupt
open VaptVupt.xcodeproj
```

1. Selecione o destino **iPhone 15 / iOS 17+** (ou superior).
2. `⌘R` para compilar e executar.
3. Na primeira execução, autorize **notificações** (necessário para o timer do Modo Cozinha).

---

## Testes

- **Unit**: `VaptVuptTests/` (Swift Testing).
- **UI**: `VaptVuptUITests/` (XCUIAutomation).

```bash
# Via xcodebuild
xcodebuild test -scheme VaptVupt -destination 'platform=iOS Simulator,name=iPhone 15'
```

---

## Roadmap

Implementado:

- [x] **Feedback háptico** via `.sensoryFeedback` em favoritos (`RecipeCard`, `RecipeDetailView`), Despensa, estado da IA no Upload e Modo Cozinha (troca de passo, timer iniciado, timer zerado).
- [x] **Proximity Sensor** (`ProximityObserver`) integrado ao Modo Cozinha — passe a mão por cima da câmera frontal para avançar o passo.
- [x] **Comandos de voz** (`VoiceCommandRecognizer` com `SFSpeechRecognizer` pt-BR) — "próximo", "voltar", "pausar", "continuar", "iniciar", "cancelar".
- [x] **ActivityKit / Live Activity** do timer: `CookingActivityAttributes` + integração em `CookingTimerController` (start / update / end).
- [x] **VisionKit DataScanner** (`PantryScannerView`) na Despensa para captura de rótulos pela câmera.
- [x] **Compartilhar & Importar receitas** via deep link `vaptvupt://import?data=...` — `RecipeShareService` codifica/decodifica o payload, o `shareText` inclui o link mágico, `ImportRecipePreviewView` mostra preview com confirmação, e o campo "Colar Link" do Upload detecta o esquema automaticamente.

Em standby (código pronto, faltando setup no Xcode/contas):

- [~] **Widget Extension** (WidgetKit) com Receita do Dia + **UI da Live Activity** — código pronto em [`VaptVuptWidget/`](./VaptVuptWidget/README.md). Falta criar o target Widget Extension no Xcode e marcar os arquivos compartilhados — instruções no README do widget.
- [~] **Camada de Repository** para favoritos/despensa — protocolos `FavoritesRepository` e `PantryRepository` + implementação local em `Data/Repositories/` (na verdade `Domain/Repositories/`). Quando definir o backend, basta criar uma `FirebaseFavoritesRepository` ou `SupabaseFavoritesRepository` e injetar em `VaptVuptApp`.

Pendentes:

- [ ] **App Clips** para compartilhamento de receitas.
- [ ] Backend real (Firebase / Supabase) substituindo `UserDefaults` — abstração já pronta.
- [ ] Integração de LLM real no `RecipeAIService` (Gemini / Claude / GPT).

### Configuração necessária no Xcode

Para que os novos recursos funcionem em runtime, adicione no Info.plist do target:

| Chave | Valor | Recurso |
|---|---|---|
| `NSSpeechRecognitionUsageDescription` | "Usamos reconhecimento de fala para você controlar a receita por voz." | Comandos de voz |
| `NSMicrophoneUsageDescription` | "O microfone é usado para os comandos de voz no Modo Cozinha." | Comandos de voz |
| `NSCameraUsageDescription` | "A câmera é usada para escanear rótulos e adicionar à sua despensa." | DataScanner |
| `NSSupportsLiveActivities` | `YES` | Live Activity do timer |
| `CFBundleURLTypes` | `[{ CFBundleURLName = "com.lhcbernardes.vaptvupt.import", CFBundleURLSchemes = ["vaptvupt"] }]` | Compartilhar/importar receitas |

Para a UI do Widget e da Live Activity, adicione um novo target **Widget Extension** (File → New → Target) e marque `CookingActivityAttributes.swift` como membro também desse target.

#### Compartilhar & importar receitas

- O botão de compartilhar no detalhe (`RecipeDetailView`) gera um texto formatado com o link mágico `vaptvupt://import?data=<base64url>` ao final.
- Quem tem o app instalado abre o link e cai em `ImportRecipePreviewView` (preview + confirmação) antes de adicionar ao Dashboard.
- Quem não tem o app vê apenas o texto legível da receita.
- No fluxo de Upload, colar um link `vaptvupt://...` no campo "Colar Link" importa direto, pulando a chamada da IA.

---

## Licença

Projeto pessoal — todos os direitos reservados a [@lhcbernardes](https://github.com/lhcbernardes).
