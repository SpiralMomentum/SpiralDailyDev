# Phase 2 Integration Design — news_reader

## Context

Phase 1 MVP (feed, detail, bookmarks) is committed. Phase 2 feature code (comments, search, settings, onboarding, SQL bookmarks, core infra) is written but not wired into the app.

## Goal

Integrate all existing Phase 2 code so every screen is reachable and functional with mock data sources.

## Scope

### 1. ServiceLocator Expansion

Add registrations for:
- DatabaseHelper (singleton, lazy)
- SqlBookmarkLocalDataSource replacing InMemoryBookmarkLocalDataSource
- SyncBookmarks UseCase
- SettingsDataSource (InMemorySettingsDataSource initially)
- SettingsRepository, GetSettings, UpdateSettings
- CommentDataSource (MockCommentDataSource), CommentRepository, WatchComments, AddComment
- SearchRemoteDataSource (MockSearchRemoteDataSource), SearchHistoryDataSource (InMemorySearchHistoryDataSource), SearchRepository, SearchArticles

### 2. Router Integration

Implement 4 missing GoRouter routes:
- /onboarding -> OnboardingPage
- /article/:id/comments -> CommentsPage + CommentsBloc
- /search -> SearchPage + SearchCubit
- /settings -> SettingsPage + SettingsCubit

### 3. App Startup Flow

- Initialize DatabaseHelper in main()
- Check onboarding completion -> conditional initial route (/onboarding or /feed)

### 4. Theme/Locale Binding

- Global SettingsCubit via BlocProvider at App level
- MaterialApp.router binds themeMode and locale to SettingsCubit state

### 5. Navigation Links

- Feed AppBar: search icon, settings icon
- Article detail: comments button
- Settings accessible from feed

## Non-Goals

- Real API integration (stays on mock data sources)
- SharedPreferences initialization (use InMemory for now)
- Push notifications
