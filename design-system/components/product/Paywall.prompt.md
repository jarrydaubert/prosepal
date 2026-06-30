The upgrade screen. Leads with felt value, lists a few real benefits, offers two plans, one confident CTA. Premium and unhurried — no countdowns, no guilt.

```jsx
<Paywall
  title="Write without limits"
  sub="Unlimited refines, every tone, and your private voice profile."
  features={[
    { icon: <i className="ph ph-infinity" />, title: "Unlimited refines", sub: "Polish as many messages as you like" },
    { icon: <i className="ph ph-user-focus" />, title: "Your voice profile", sub: "ProsePal learns how you sound" },
    { icon: <i className="ph ph-lock-simple" />, title: "Private by default", sub: "Nothing trains on your words" },
  ]}
  plans={[
    { id: "year", name: "Yearly", meta: "12 months", price: "$39.99", per: "/yr", badge: "Save 40%" },
    { id: "month", name: "Monthly", price: "$5.99", per: "/mo" },
  ]}
  value={plan} onSelect={setPlan}
  cta="Start 7-day free trial"
  fine={<>Cancel anytime · <a href="#">Restore</a> · <a href="#">Terms</a></>}
/>
```

Keep to ≤ 4 features and 2 plans. The yearly plan carries the sage savings badge.
