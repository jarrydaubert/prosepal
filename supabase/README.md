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

## Email Setup

Currently using Supabase built-in email (rate limited for testing).

**Pre-Launch Task** (see `docs/LAUNCH_CHECKLIST.md`):
- Configure custom SMTP in Supabase Dashboard > Settings > Auth > SMTP
- Recommended: Resend, SendGrid, or Postmark
- Required for production email delivery (magic links, password reset)
