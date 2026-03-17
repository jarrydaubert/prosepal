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

## send-feedback

Relays authenticated in-app feedback to the support inbox through Resend.

**Deployed to:** `mwoxtqxzunsjmbdqezif`

### Required secrets
- `RESEND_API_KEY`
- `FEEDBACK_TO_EMAIL`
- `FEEDBACK_FROM_EMAIL`
- existing `SUPABASE_URL` / `SUPABASE_ANON_KEY`

### Deploy changes
```bash
supabase functions deploy send-feedback --project-ref mwoxtqxzunsjmbdqezif
```

### Test locally
```bash
supabase functions serve send-feedback
```

## Email Setup

Currently using Supabase built-in email (rate limited for testing).

**Pre-Launch Task** (see `docs/LAUNCH_CHECKLIST.md`):
- Configure custom SMTP in Supabase Dashboard > Settings > Auth > SMTP
- Recommended: Resend, SendGrid, or Postmark
- Required for production email delivery (magic links, password reset)
