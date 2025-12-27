# Supabase Edge Functions

## delete-user

Handles account deletion (App Store requirement).

**Deployed to:** `mwoxtqxzunsjmbdqezif`

### Deploy changes
```bash
supabase functions deploy delete-user --project-ref mwoxtqxzunsjmbdqezif
```

### Test locally
```bash
supabase functions serve delete-user
```

## Email Setup (TODO)

Currently using Supabase built-in email (rate limited).

Before App Store launch, set up custom SMTP:
- [ ] Purchase domain (prosepal.app)
- [ ] Set up Resend/SendGrid
- [ ] Configure in Supabase Dashboard > Settings > Auth > SMTP
