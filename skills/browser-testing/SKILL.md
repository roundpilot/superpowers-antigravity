---
name: browser-testing
description: Use when completing frontend or UI work that needs visual verification, before claiming the UI is correct
---

# Browser Testing

## Overview

Never claim UI work is correct without visual evidence. Browser automation makes verification fast and produces artifacts the user can review.

**Core principle:** Evidence before assertions. Screenshots and DOM inspection prove correctness; text descriptions don't.

**When to use:** After implementing any UI or frontend changes, before claiming the work is correct.

## The Process

1. **Navigate** to the page under test using browser automation
2. **Screenshot** the current state — embed in walkthrough artifact
3. **Inspect DOM** to verify structure matches expectations (correct elements, classes, attributes)
4. **Record a walkthrough** of the key user flow (if multi-step interaction)
5. **Embed evidence** in a walkthrough artifact with screenshots and recordings

## Quick Reference

| What to verify | Tool | Output |
|---------------|------|--------|
| Visual appearance | Screenshot | `![description](/path/to/screenshot.png)` |
| DOM structure | Inspect elements | Element presence, attributes, classes |
| User flow | Recording | Embedded video in artifact |
| Responsive layout | Screenshot at viewport | Multiple screenshots at different widths |

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Not waiting for page load before screenshot | Wait for key elements to be visible |
| Checking only one viewport size | Test at desktop (1280px) and mobile (375px) minimum |
| Visual-only verification (no DOM check) | Always inspect DOM structure — visual can hide broken markup |
| Forgetting to embed evidence | Every claim needs a screenshot or recording in the artifact |
| Saying "looks correct" without proof | Take the screenshot. Embed it. Let the user judge. |

**Evidence classification in artifacts:** Use GitHub-style alerts:
- `> [!TIP]` for passing checks
- `> [!CAUTION]` for failing checks
- `> [!NOTE]` for observations that need human judgment

## Integration

- **superpowers:verification-before-completion** — browser-testing is specialized verification for UI work
- **superpowers:test-driven-development** — browser tests complement unit tests, they don't replace them

## Starting the Browser

The `browser` subagent does the testing (navigation, screenshots, console and network checks, recordings) and returns evidence for the walkthrough artifact. It does not add browser tools to your own session.

- **2.0 app 2.30+, personal Google account:** the built-in browser agent is on, and you can start `browser` subagents yourself, one or several in parallel, each in its own tab. Delegate the check when it needs live rendering, clicks, form input, responsive layout or console output.
- **CLI, IDE, and business or enterprise accounts:** `/browser` is the only way in. Recommend it to your human partner with the exact check to run. In the CLI it drives their local Chrome 144+.

If you cannot tell which case applies, recommend `/browser`: it works everywhere.
