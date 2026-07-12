# System Surfaces and Moment Handoff

ProsePal has three optional ways to begin outside the main app: App Intents and
Shortcuts, a widget/control extension, and a Share Extension. Each surface may
prepare a Moment, but none may generate text, own account state, or bypass the
main app’s validation and draft-protection flow.

## Boundary

```text
App Intent / Shortcut ----> standard UserDefaults launch request --+
Widget / Control ---------> prosepal://moment deep link ------------+--> app root
Share Extension ----------> app-group payload + deep link ----------+    -> MomentModel
```

The app root always selects the Moment destination and applies the sanitized
launch request to `MomentModel`. Writing still begins only after the user taps
the explicit draft action.

## Shared launch types

`ProsePalAppIntents.swift` owns the app-side handoff types:

| Type | Responsibility |
|---|---|
| `MomentLaunchRequest` | Optional person, occasion, shared text, allowlisted source, and creation time |
| `MomentLaunchStore` | One-time App Intent payload in standard `UserDefaults` |
| `SharedMomentLaunchPayload` | Text/URL payload for an app-group handoff |
| `SharedMomentLaunchStore` | One-time app-group persistence and consumption |
| `MomentDeepLink` | Parses the production `prosepal://moment` route |

Launch stores consume by removing the stored value before decoding it. A
handoff is therefore not silently replayed on every launch.

## App Intent and Shortcuts

`StartMomentIntent` is discoverable and runs in a foreground-opening mode. It
accepts an optional person and occasion string, normalizes them into a
`MomentLaunchRequest`, stores that request, and returns “Opening ProsePal.”

The App Shortcuts provider publishes these phrases:

- “Start a moment in ProsePal”;
- “Write with ProsePal”; and
- “Open ProsePal for someone”.

Unknown occasion text is ignored rather than being trusted as a new domain
value.

## Widget and Control

The widget target contains:

- `CareGlanceWidget` for small, accessory-circular, and
  accessory-rectangular families; and
- `StartMomentControlWidget` for Control Center or an Action Button route.

Both open a Moment deep link. They carry only an allowlisted source marker and
do not place message content in the URL.

Widget kind and URL-scheme values are selected from the extension bundle ID.
The production target uses `prosepal`; the staging extension constructs
`prosepal-staging`.

## Share Extension

The Share Extension accepts plain text, text, and at most one web URL. It:

1. loads supported attachments;
2. combines URL and text fragments;
3. trims and caps shared text to 1,200 characters;
4. previews the sanitized context;
5. writes a one-time payload to `group.com.prosepal.prosepal`; and
6. asks the system to open the app with source `share_extension`.

The main app consumes shared app-group data only when the deep link carries that
source. Arbitrary URLs cannot make it read pending shared text.

The extension currently carries a target-local payload/store implementation so
it can compile independently. The canonical extension-safe contract and target
membership consolidation are tracked in [BACKLOG.md](../BACKLOG.md).

## Sanitization and trust

- Person names use the domain’s 80-character, single-line policy.
- Shared text uses the 1,200-character Moment-detail policy.
- Occasion text must match a raw value or normalized display name.
- Deep-link sources are restricted to `app_intent`, `control_center`,
  `deep_link`, `share_extension`, `shortcut`, or `widget`.
- Deep links do not accept arbitrary shared message text.
- Diagnostics record source and counts, not the person or shared content.

## Current staging boundary

`MomentDeepLink` currently accepts the production `prosepal` scheme, while the
staging widget and Share Extension construct `prosepal-staging`. This is why the
optional targets remain release-qualified surfaces rather than assumed v1
features. The shared launch-contract backlog item owns production/staging route
convergence.

## Release rule

Each optional target ships only when its production-like target can launch from
the real system surface, hand off once, preserve sanitized context, and leave
the main Moment loop stable. A target that cannot pass is removed from the v1
candidate rather than weakening the app.

## Source map

- `prosepal-ios/Sources/ProsePalUI/ProsePalAppIntents.swift`
- `prosepal-ios/Sources/ProsePalUI/MomentExperienceView.swift`
- `prosepal-ios/Widgets/ProsePalWidgets.swift`
- `prosepal-ios/ShareExtension/ShareViewController.swift`
- `prosepal-ios/App/ProsePal.entitlements`
- `prosepal-ios/ShareExtension/ProsePalShareExtension.entitlements`
- `prosepal-ios/Tests/ProsePalUITests/ProsePalAppIntentsTests.swift`
- `prosepal-ios/Tests/ProsePalUITests/SystemSurfaceProjectTests.swift`

## Related documentation

- [User journeys](../product/user-journeys.md)
- [Testing](../quality/testing.md)
- [Native release](../operations/release.md)
