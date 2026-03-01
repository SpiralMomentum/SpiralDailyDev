enum AppRoutes {
  onboarding,
  feed,
  articleDetail,
  comments,
  bookmarks,
  search,
  settings,
}

extension AppRoutesPath on AppRoutes {
  String get path {
    switch (this) {
      case AppRoutes.onboarding:
        return '/onboarding';
      case AppRoutes.feed:
        return '/feed';
      case AppRoutes.articleDetail:
        return '/article/:id';
      case AppRoutes.comments:
        return '/article/:id/comments';
      case AppRoutes.bookmarks:
        return '/bookmarks';
      case AppRoutes.search:
        return '/search';
      case AppRoutes.settings:
        return '/settings';
    }
  }
}
