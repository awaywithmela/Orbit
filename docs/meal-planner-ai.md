# Meal planner AI

The development client calls OpenRouter using `nvidia/nemotron-3-ultra-550b-a55b:free`.
The screen requests a complete JSON response, lets the user review it, and saves accepted meals to Isar locally. The prompt sends only meal preferences, not the local database.

Create an ignored `.env.local.json` file with `{"OPENROUTER_API_KEY":"your-development-key"}` and run:

```sh
flutter run --dart-define-from-file=.env.local.json
```

Never commit a real key. A compile-time key is extractable from an app binary. Direct shared-key requests are disabled in release builds. For App Store AI, use an authenticated, rate-limited relay that holds the key server-side, or design a user-owned-key flow. A relay need not store app records; saves can remain entirely in Isar. No relay has been deployed.

Free-model availability and rate limits can change. Manual meal entry works without this service. Network failures, authorization failures, rate limits, and invalid or incomplete responses produce recoverable messages; incomplete plans are not saved.
