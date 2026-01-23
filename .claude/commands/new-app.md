---
description: Create new app from prosepal blueprint
argument-hint: [app-name]
---

# /new-app - Create New App from Blueprint

Guide the creation of a new app from the prosepal blueprint.

## Usage
```
/new-app [app-name]
```

**Example:**
- `/new-app captionpal`

## Process

### Phase 1: Setup (Day 1)

**1. Copy Blueprint**
```bash
cp -r prosepal [app-name]
cd [app-name]
```

**2. Update Identifiers**
- [ ] `pubspec.yaml`: name, description, bundle ID
- [ ] `android/app/build.gradle.kts`: applicationId
- [ ] Xcode: Bundle Identifier in Runner target
- [ ] Search/replace `com.prosepal.prosepal` with new bundle ID

**3. Create External Services**
- [ ] Firebase project: `flutterfire configure`
- [ ] Supabase project: Run ALL migrations from `supabase/migrations/` in order
- [ ] Supabase: Verify RLS enabled on all tables
- [ ] Supabase: Verify sensitive tables (user_usage, etc.) block direct writes
- [ ] RevenueCat app: Configure products/entitlements
- [ ] RevenueCat webhook: Set up with Supabase edge function URL + secret

**4. Update Service Config**
- [ ] `main.dart`: Supabase URL/key
- [ ] `subscription_service.dart`: RevenueCat API keys (via dart-define)
- [ ] `ai_config.dart`: Adjust model/prompts if needed

### Phase 2: Customize (Days 2-3)

**5. Replace Domain Content**
- [ ] `core/models/`: Your domain models
- [ ] `features/`: Your app screens
- [ ] `ai_service.dart`: Your AI prompts

**6. Update Branding**
- [ ] App icons (all sizes)
- [ ] Splash screen
- [ ] Theme colors in `app_colors.dart`
- [ ] App name in native configs

### Phase 3: Verify (Day 4)

**7. Test Core Flows**
```bash
flutter analyze
flutter test
flutter run
```

- [ ] Auth flow works
- [ ] Core feature works
- [ ] Purchases work (sandbox)

**8. Create App CLAUDE.md**
Create `[app-name]/CLAUDE.md` with app-specific context.

## Reference
- Full details: `prosepal/docs/STACK_TEMPLATE.md`
- Cloning strategy: `prosepal/docs/CLONING_PLAYBOOK.md`
