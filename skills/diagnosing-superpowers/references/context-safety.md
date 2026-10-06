# Context safety for session transcripts

One transcript record can exceed a megabyte or embed a whole history. Printing
one whole record can overflow the context of the session doing the diagnosis.
Every reader of a session file, controller or subagent, follows these rules for
every file, every time.

1. **Measure before reading.**

   ```bash
   wc -lc "$F"
   awk '{ if (length($0) > 100000) print NR, length($0) }' "$F"   # long lines
   ```

2. **Never `cat` or `grep` for content.** Get line numbers and counts
   first (`grep -n … | cut -d: -f1`, `jq -r '.type' | sort | uniq -c`),
   then small fields from specific lines (`sed -n Np | jq -c '{…}'` or
   `| cut -c1-500`). Use the field-extraction commands established during
   discovery for the source in front of you.
3. **Narrow anything over 500 characters.** If a command returns more than
   500 characters for one record, tighten the field or the slice.
4. **Read-only.** Never modify, move, or delete a session file.

## Without a POSIX shell

`run_command` may run PowerShell or Command Prompt instead of a POSIX shell. The four rules still apply; these PowerShell forms do the same jobs. Each line is one complete command: put the absolute path in `$F` on the same line.

```powershell
# 0. List files with size and time
Get-ChildItem -Path '<absolute directory>' -Recurse -File -Filter transcript.jsonl | Sort-Object LastWriteTime -Descending | Format-List FullName, Length, LastWriteTime

# 1. Measure: bytes, line count, and lines longer than 100,000 characters
$F = '<absolute path>'; (Get-Item $F).Length
$F = '<absolute path>'; $n = 0; foreach ($l in [IO.File]::ReadLines($F)) { $n++; if ($l.Length -gt 100000) { 'line ' + $n + ': ' + $l.Length } }; 'lines: ' + $n

# 2. Line numbers and counts first
$F = '<absolute path>'; Select-String -Path $F -SimpleMatch '<text>' | ForEach-Object LineNumber
$F = '<absolute path>'; [IO.File]::ReadLines($F) | ConvertFrom-Json | Group-Object type | Select-Object Count, Name

# 2-3. Small fields from one line, never more than 500 characters
$F = '<absolute path>'; $l = [IO.File]::ReadLines($F) | Select-Object -Skip (<line> - 1) -First 1; $l.Substring(0, [Math]::Min(500, $l.Length))
$F = '<absolute path>'; [IO.File]::ReadLines($F) | Select-Object -Skip (<line> - 1) -First 1 | ConvertFrom-Json | Select-Object <field>, <field>
```

Under Command Prompt, run each line as `powershell -NoProfile -Command "<line>"`. The lines use single quotes only, so they need no further escaping.

The prohibition in rule 2 covers printing `Get-Content` or `Select-String` output: take `LineNumber` only. The file viewer and text-search tools also return whole lines; on a session file, use them only for lines you have measured at 500 characters or fewer.

On Windows these lines cannot be split cleanly into words, so an allow rule covers one only if it matches the whole line; otherwise expect an approval for each command. Give a measurement a `WaitMsBeforeAsync` long enough to finish. If it moves to the background anyway, collect it with `manage_task` (`Action: "status"`), and never report while it is still running.

Record the form that worked in the case file so every reader reuses it.
