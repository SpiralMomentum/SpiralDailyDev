# app_navigation

Shared navigation helpers for Spiral applications built on top of `go_router`.

## Features

- Common `RoutesController` contract
- Configurable `GoRouterRoutesController` implementation supporting path or
  name based navigation strategies

## Usage

```dart
final controller = GoRouterRoutesController(
  routesBuilder: () => AppRoutes.values.map((route) => route.getRouter).toList(),
  navigationType: GoRouterNavigationType.path,
);
```
