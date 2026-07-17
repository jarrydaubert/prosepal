Shows the user's plan and server-supplied allowance metadata. The upgrade path
stays calm, never nagging.

```jsx
<UsageCard
  {...serverUsage}
  action={<Button block variant="secondary" size="md">View Pro options</Button>}
/>
```

Render this only from approved structured server metadata. Never invent counts,
reset dates, or static allowance examples. For Pro, omit the action or show
“Manage plan”.
