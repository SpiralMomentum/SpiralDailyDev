enum AppRoutes {
  feed,
  articleDetail,
  bookmarks,
}

extension AppRoutesPath on AppRoutes {
  String get path {
    switch (this) {
      case AppRoutes.feed:
        return '/';
      case AppRoutes.articleDetail:
        return '/article/:id';
      case AppRoutes.bookmarks:
        return '/bookmarks';
    }
  }
}
