## Summary

- What changed?
- Why did it change?

## Risk

- User-facing risk:
- Operational/security risk:
- Rollback plan:

## Validation

- [ ] `cd prosepal-ios && swift build` passes
- [ ] `cd prosepal-ios && swift test --quiet` passes
- [ ] `cd prosepal-ios && xcodebuild -project ProsePal.xcodeproj -target ProsePal -sdk iphonesimulator CODE_SIGNING_ALLOWED=NO build` passes
- [ ] Relevant integration/device checks run when behavior changed
- [ ] For UI changes: simulator/device screenshots reviewed and evidence attached
- [ ] Docs updated for behavior/process changes
- [ ] Commit trailers reviewed (`Co-authored-by` present only when intentional and explicitly approved)

## Release Notes

- [ ] Label applied for release categorization (`feature`, `fix`, `breaking`, `security`, `chore`, `ci`, `dependencies`)
- [ ] Breaking changes are explicitly called out in PR body if applicable
