# PresentationStack

A SwiftUI library for a **programmable presentation stack**. Manage presenting and dismissing multiple sheets/fullScreenCover the way you use `NavigationStack` + `NavigationPath`.

## Why PresentationStack?

SwiftUI’s built-in `.sheet`/`.fullScreenCover` works well for a single modal, but these cases get painful quickly:

- **Programmatically** present or dismiss presentation from anywhere (deep links, global routing)
- **Stack presentations** on top of an already presented sheet with a manageable path

PresentationStack offers a unified stack API and declarative destinations so presentation behave more like a navigation stack.

## Features

- **Programmable stack** — `present` / `dismiss` via `PresentationManager` (alias `PresentationPath`), including dismiss-to-root, dismiss last *N*, and dismiss to a specific item
- **Declarative destinations** — `presentationDestination(for:)` registers sheet content by type, similar to `navigationDestination`

## Requirements

- iOS 18+

## Installation

Add both packages in Xcode or `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/TStrawberry/PresentationStack.git", extract: "v1.0.0"),
]
```

## Quick start

### 1. Create a path

`PresentationPath` is a type alias for `PresentationManager`. Keep it for any further usage:

```swift
import SwiftUI
import PresentationStack

@Observable
@MainActor
final class AppRouter {
    var path = PresentationPath()
}

struct RootView: View {
  @State private var router = AppRouter()

  var body: some View {
    PresentationStack(path: router.path) {
      HomeScreen()
        .presentationDestination(for: String.self) { name in
          DetailScreen(name: name)
        }
    }
  }
}
```

### 2. Present programically 

From any child view, call the shared path inside a `Task`:

```swift
Button("Open detail") {
  Task {
    await router.path.presentSheet("detail-1")
  }
}
```

The value passed to `presentSheet` must be `Hashable & Sendable`, and its type must be registered with `presentationDestination(for:)` on the root or an ancestor.


### 3. Present as usual

If you want to continue using SwiftUI’s original sheet/fullScreenCover APIs, you just need to prefix the call with `withPresentationStack` to integrate it with the presentation stack.

```swift
var body: some View {
  SomeView()
    .withPresentationStack.fullScreenCover(item: $text) { text in
      Screen()
    }
}
```

### 4. Dismiss

```swift
// Dismiss every presentation back to the root
await router.path.dismissToRoot()

// Dismiss the top two
await router.path.dismissLast(2)
```

When the user swipes a sheet away, the stack updates automatically.


## Demo

The `Demo/` app shows:

- A `TabView` with a separate `NavigationStack` per tab
- Reading and updating `@ValueEntry` fields on the current `screenContext`
- Stack operations: `presentSheet`, `dismissToRoot`, `dismissLast`
- A `NavigationStack` inside a sheet destination, wired into the presentation stack

Open `Demo/Demo.xcodeproj` in Xcode and run.


**The demo also demonstrates how to build a complete app framework by combining PresentationStack with techniques such as NavigationValues, and print the graph of the whole app and more. Please check out.**

## License

[MIT](LICENSE)
