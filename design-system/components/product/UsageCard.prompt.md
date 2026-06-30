Shows the user's plan and how much of their allowance remains — the bar turns amber when running low. The upgrade path stays calm, never nagging.

```jsx
<UsageCard
  plan="Free" used={7} total={10} unit="refines" period="this week" reset="resets Mon"
  action={<Button block variant="secondary" size="md">Upgrade to Pro</Button>}
/>
```

Drop into Settings or the Drafts header. For Pro, pass `plan="Pro"` and omit the action (or show "Manage plan").
