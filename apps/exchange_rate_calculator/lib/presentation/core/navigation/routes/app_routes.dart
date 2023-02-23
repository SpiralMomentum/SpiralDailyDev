enum AppRoutes {
  HOME,
}

extension AppRoutesPath on AppRoutes {
  String get path {
    switch (this) {
      case AppRoutes.HOME:
        return '/';
      default:
        return '/';
    }
  }
}


