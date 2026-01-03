enum AppRoutes {
  home,
  memo,
}

extension AppRoutesPath on AppRoutes {
  String get path {
    switch (this) {
      case AppRoutes.home:
        return '/';
      case AppRoutes.memo:
        return '/memo';
      default:
        return '/';
    }
  }
}
