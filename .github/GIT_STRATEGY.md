# SwiftTerm Contribution - Git Strategy

## Branch Structure

```
main (upstream)
 │
 └── feature/utf8-ime-support (IME/Korean input fix)
      │   Commit: b8bed88
      │   Status: Ready for PR
      │
      └── feature/resize-fix (Window resize fix)
            Commit: fac855e
            Status: Ready for PR
```

## Branches Overview

| Branch | Purpose | Base | Status |
|--------|---------|------|--------|
| `feature/utf8-ime-support` | Fix Korean/CJK IME input handling | main | Complete |
| `feature/resize-fix` | Fix terminal not resizing with window | feature/utf8-ime-support | Complete |

## Features Summary

### 1. IME Support (feature/utf8-ime-support)
- **Problem**: Korean/CJK input composition not working properly
- **Solution**: Add IME composition preview overlay, improve setMarkedText handling
- **Files**: MacTerminalView.swift, MacIMECompositionView.swift, AppleIMESupport.swift, etc.

### 2. Window Resize Fix (feature/resize-fix)
- **Problem**: Terminal columns/rows not updating when window resized via Auto Layout, NSSplitView, etc.
- **Solution**: Call `processSizeChange()` in `setFrameSize(_:)` and `resizeSubviews(withOldSize:)`
- **Files**: MacTerminalView.swift (+8 lines)

## Testing Strategy

**Test both features together:**
```bash
git checkout feature/resize-fix
# This branch contains BOTH fixes (IME + resize)
# Run TerminalApp and test:
# 1. Korean/Japanese/Chinese input
# 2. Window resize, maximize, split view
```

## PR Strategy Options

### Option A: Single PR (Recommended for testing together)
```bash
# Create PR from feature/resize-fix -> main
# This includes both IME and resize fixes
gh pr create --base main --head feature/resize-fix
```

### Option B: Sequential PRs (Cleaner history)
```bash
# Step 1: PR for IME fix
gh pr create --base main --head feature/utf8-ime-support
# Wait for merge

# Step 2: Rebase resize branch onto main
git checkout feature/resize-fix
git rebase main

# Step 3: PR for resize fix
gh pr create --base main --head feature/resize-fix
```

## Commands Reference

```bash
# Switch to test both features
git checkout feature/resize-fix

# Switch to test only IME
git checkout feature/utf8-ime-support

# View branch structure
git log --oneline --graph feature/resize-fix feature/utf8-ime-support main -15

# Push branches to your fork
git push -u origin feature/utf8-ime-support
git push -u origin feature/resize-fix
```

## Notes

- `feature/resize-fix` is stacked on top of `feature/utf8-ime-support`
- Testing `feature/resize-fix` automatically tests both features
- All 207 tests pass on `feature/resize-fix`

---
*Last updated: 2025-01-19*
