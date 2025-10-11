# Quote Companion

Quote Companion is a Clean Architecture Flutter service that surfaces inspirational quotes
across the status bar, lock screen, and widgets. The experience encourages daily reflection
while allowing users to curate their own catalogue of quotes.

## Goals
- Deliver uplifting messages on glanceable surfaces such as the notification tray, lock screen, and widgets.
- Allow users to create and manage personal quotes alongside curated content.
- Provide a feedback loop (VOC) so the product team can iterate quickly.
- Respect privacy with encrypted local storage and a minimal data collection policy.

## Architecture Overview
The project follows a classic Clean Architecture layering strategy.

```
lib/
└─ src/
   ├─ domain/          # Entities, repositories, and use-cases
   ├─ data/            # Data sources, models, and repository implementations
   ├─ presentation/    # Riverpod state, widgets, and localized strings
   └─ di/              # Dependency wiring
```

### Domain Layer
- `Quote`, `QuoteDisplayPreferences`, and `FeedbackEntry` model the core business concepts.
- Repository contracts (`QuoteRepository`) express the APIs the upper layers depend on.
- Use-cases (`WatchActiveQuote`, `AddCustomQuote`, `SubmitFeedback`, etc.) encapsulate
  business rules.

### Data Layer
- `SecureQuoteLocalDataSource` stores user-provided quotes with `flutter_secure_storage`
  and persists preferences and VOC submissions via `SharedPreferences`.
- `QuoteRepositoryImpl` orchestrates data sources, keeps curated fallbacks, and exposes
  streams back to the domain layer.

### Presentation Layer
- Riverpod is used for state management via `QuoteNotifier`.
- Localization is handled through a lightweight `AppLocalizations` delegate with English,
  Korean, and Japanese translations to reflect our primary target markets.
- Widgets incorporate accessibility semantics to support screen readers and large text.

## VOC (Voice of Customer) Flow
1. Users can submit feedback directly inside the app. Submissions are stored locally and
   queued for batch upload by future background jobs.
2. A weekly reminder nudges users to complete a mini-survey sourced from remote config.
3. Product teams review aggregated VOC data during sprint planning and prioritise
   improvements.

A detailed flow diagram is documented in `docs/voc_process.md` (to be added during the
integration phase).

## Security & Privacy
- Custom quotes are encrypted using a randomly generated key stored in the platform keychain
  (via `flutter_secure_storage`).
- Preferences and feedback metadata are stored using `SharedPreferences` with only the
  minimum required fields.
- No quote content leaves the device without explicit user opt-in.
- The repository exposes hooks for secure sync jobs, but network calls are deferred until
  the backend contract is finalised.

## Testing & CI/CD
- Unit tests cover domain use-cases and repository behaviours with mocked data sources.
- Widget tests ensure the main dashboard renders correctly on various locales.
- CI runs `flutter analyze`, `flutter test`, and integration smoke tests on physical devices
  to validate status bar and widget experiences.

## Localization & Accessibility
- Strings live in `AppLocalizations` and can be extended with `arb` files when the project
  enables Flutter's `gen_l10n` tool.
- Widgets adopt `Semantics`, `ListView.separated`, and accessible colours from the shared
  design system (`ui_components` package).

---

For development setup instructions refer to the root `SERVICE_PUBLISH_GUIDE.md`.
