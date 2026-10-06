# GitHub issues

Issues for this port go to `roundpilot/superpowers-antigravity`. Use `gh` when it is installed and authenticated; it handles auth, rate limits, and JSON. Fall back to fetching with `read_url_content`, then to a URL your partner opens.

## Search

```
gh search issues --repo roundpilot/superpowers-antigravity --limit 10 "<terms>" --json number,state,title
```

Without `gh` (unauthenticated, 10 requests a minute), fetch this with `read_url_content` and read each item's `number`, `state` and `title`:

```
https://api.github.com/search/issues?q=repo:roundpilot/superpowers-antigravity+is:issue+<url-encoded terms>&per_page=10
```

If that is refused or its text is unreadable, fetch the same search as a web page with `read_url_content`:

```
https://github.com/roundpilot/superpowers-antigravity/issues?q=is:issue+<url-encoded terms>
```

If that fails too, hand over that URL for your partner to open.

## File

Write the filled `templates/issue.md` to the case workspace and show the exact text. Ask for approval with `ask_question` (file it / change it first / do not file). An approval is your partner's own answer: if you would be settling it yourself because nobody can answer, the answer is "do not file"; leave the text in the case workspace and stop. After approval:

```
gh issue create --repo roundpilot/superpowers-antigravity --title "<title>" --body-file <path> --label bug --label automated-issue-report
```

GitHub drops labels silently when the reporter lacks push access, so the labels land only for collaborators; the template footer still marks the issue as skill-filed. `gh` cannot attach files: give your partner the bundle path to attach through the browser after the issue exists.

Without `gh`, or if `gh issue create` fails, hand over a prefilled link on the `diagnosis_report.md` template, which applies both labels for any reporter:

```
https://github.com/roundpilot/superpowers-antigravity/issues/new?template=diagnosis_report.md&title=<url-encoded title>&body=<url-encoded body>
```

GitHub rejects URLs over about 8,000 characters; past that, send the link with the title only and tell your partner to paste the body from the file.

A GitHub MCP server your partner has configured serves the same purpose under the same approval rule.
