# BUGÜN Flutter project

## What changed in this revision
- Split the formerly ~3,300-line `RecommendationScreen` into smaller library parts, while keeping its existing state and method behavior together in one Dart library. This avoids copying state or changing navigation contracts during the first refactor.
  - `recommendation_screen.dart`: screen state, lifecycle, and top-level layout.
  - `recommendation_location.dart`: optional location and distance display.
  - `recommendation_filter_controls.dart` / `recommendation_filter_widgets.dart`: filter state, date controls, and filter UI.
  - `recommendation_logic.dart` / `recommendation_matching.dart`: recommendation generation, scoring, and matching rules.
  - `recommendation_queue.dart`: queue, route, ticket, and detail navigation.
  - `recommendation_card_image.dart` / `recommendation_cards.dart`: card image and result-card UI.
- Replaced the placeholder profile screen with Supabase email/password sign-in, account creation, password-reset request, city selection, interests, privacy information, and an optional foreground location permission flow.
- Added `CityPreferenceService`: signed-in users read/write the city on their Supabase profile; guests use this device's local preference. Ankara remains the fallback.
- Home, Explore, and Recommendation now read the selected city instead of always querying Ankara.
- Added `supabase/migrations/007_profile_security.sql` to enable row-level security for `profiles` and limit each account to its own row.

## Important setup before testing account features
1. Open the Supabase project SQL Editor.
2. Run the contents of `supabase/migrations/007_profile_security.sql`. This is required for the account profile access rules.
3. In Supabase Authentication settings, confirm email/password sign-in is enabled. If email confirmation is required, a new user must open the verification link before signing in.
4. Build and test the Android app on a real device. Location is optional; the app must still work when permission is denied.

## Build Android APK
From the project root, run:

```bash
flutter pub get
flutter analyze
flutter build apk --release
```

The project configuration has a Supabase URL and publishable client key for the existing development project. A publishable key is designed for client use; never place a Supabase service-role key in the Flutter app.

## Privacy note
The in-app privacy summary is not a substitute for the final legal privacy policy/KVKK disclosure. Before public release, add the operator's legal identity/contact, purposes and legal bases, retention periods, recipient groups/transfers, data-subject application method, and any relevant analytics/advertising disclosures. No push notification permission is requested in this build because push notifications are not implemented.

## Known release checks
- The refactor was checked for balanced delimiters, missing relative imports, and preservation of all 58 original screen method declarations. These are structural checks only, not a Dart compiler result.
The source package was updated here, but this environment does not have Flutter/Dart installed, so an APK build and `flutter analyze` could not be run here. Perform the build and device test in the Codespace before distributing the APK.
