#!/usr/bin/env bash
# Retired in v6.4.2 and kept for one release, so that a hooks.json made from the
# old hooks.example.json cannot block writes. Delete that hooks.json (RELEASE-NOTES).
cat >/dev/null
printf '%s\n' '{"decision":"allow"}'
