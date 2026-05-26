# VaptVuptWidget

Arquivos prontos para um target **Widget Extension** que ainda não existe no projeto Xcode. Estes arquivos **NÃO compilam no estado atual** — eles ficam aqui aguardando o target ser criado.

## Como ativar

### 1. Criar o target no Xcode

1. Abra `VaptVupt.xcodeproj`.
2. **File → New → Target… → iOS → Widget Extension**.
3. Nome: `VaptVuptWidget`. Marque **Include Live Activity**.
4. **Não** crie um App Group ainda (faremos depois, só se for usar favoritos no widget).
5. Xcode vai gerar um arquivo `VaptVuptWidget.swift` placeholder — apague-o.

### 2. Mover os arquivos para o novo target

Mova (drag & drop) estes arquivos para dentro do novo grupo `VaptVuptWidget` criado pelo Xcode:

- `VaptVuptWidgetBundle.swift`
- `CookingLiveActivity.swift`
- `RecipeOfTheDayWidget.swift`

Marque **apenas o target VaptVuptWidget** no File Inspector → Target Membership de cada arquivo.

### 3. Compartilhar arquivos com o target principal

Os arquivos abaixo já existem no target principal. Marque também o target `VaptVuptWidget` no File Inspector → Target Membership de cada um:

- `Domain/Models/CookingActivityAttributes.swift`
- `Domain/Models/Recipe.swift`
- `Domain/Models/RecipeCategory.swift`
- `Domain/Models/Ingredient.swift`
- `Domain/Models/Step.swift`
- `Data/Mock/MockRecipes.swift`

### 4. Ativar Live Activities no Info.plist do app principal

No Info.plist do target principal:

```
NSSupportsLiveActivities = YES
```

### 5. Deep link de toque no widget (opcional)

No `RootTabView`, adicione o tratamento de `vaptvupt://recipe/<UUID>` no `.onOpenURL` para abrir a tela de detalhe direto quando o usuário tocar no widget.

## Quando precisar do App Group

Apenas quando o widget for ler **estado dinâmico** (favoritos do usuário, despensa, etc.) que muda durante o uso do app. Hoje a Receita do Dia é determinística pelo dia, então não precisa.

Se for adicionar um widget de Favoritos:

1. **Signing & Capabilities → + Capability → App Groups** em ambos os targets.
2. Use o mesmo identifier nos dois: `group.com.lhcbernardes.vaptvupt`.
3. Troque `UserDefaults.standard` por `UserDefaults(suiteName: "group.com.lhcbernardes.vaptvupt")` em `LocalFavoritesRepository` / `LocalPantryRepository`.
