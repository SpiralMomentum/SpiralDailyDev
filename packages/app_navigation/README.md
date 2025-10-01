# app_navigation

Shared navigation helpers for Spiral applications built on top of `go_router`.

## Features

- Common `RoutesController` contract with stack inspection helpers
- Configurable `GoRouterRoutesController` implementation supporting path or
  name based navigation strategies

## Usage

```dart
final controller = GoRouterRoutesController(
  navigationType: GoRouterNavigationType.path,
  popAllStrategy: GoRouterPopAllStrategy.pushReplacement,
);
```
