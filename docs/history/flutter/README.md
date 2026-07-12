# Legacy Flutter Production Reference

These documents preserve the production configuration, service ownership,
App Review lessons, security posture, and runtime behavior of the archived
Flutter app.

They are intentionally kept because this material may be useful again for:

- production service custody and billing history
- Firebase, RevenueCat, Remote Config, App Check, and Flutter AI runtime context
- App Store review lessons
- migration/rollback planning
- historical debugging of the live/archived product

They are not active implementation instructions for the native iOS app on
`main`.

Full Flutter app source is preserved at:

- tag: `flutter-prod-freeze-2026-06-25`
- branch: `legacy/flutter-production-reference`

Legacy docs in this folder:

- [Architecture](./ARCHITECTURE.md)
- [AI system](./AI_SYSTEM.md)
- [Remote Config](./REMOTE_CONFIG.md)
- [Generic Remote Config template](./REMOTE_CONFIG_TEMPLATE.json)
- [Firebase Remote Config template](./REMOTE_CONFIG_TEMPLATE.firebase.json)
- [RevenueCat policy](./REVENUECAT_POLICY.md)
- [Identity mapping](./IDENTITY_MAPPING.md)
- [Service-ownership migration](./SERVICE_OWNERSHIP_MIGRATION.md)
- [Security](./SECURITY.md)
