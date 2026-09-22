#!/bin/bash
# PreToolUse/Bash: refuse xcodebuild invocations passing -derivedDataPath (see CLAUDE.md).
cmd=$(jq -r '.tool_input.command // empty')
if printf '%s' "$cmd" | grep -Eq 'xcodebuild[^;|&]*-derivedDataPath'; then
  echo "Blocked: never pass -derivedDataPath. Each extra build location registers another copy of the widget with LaunchServices and the desktop widget can keep running stale code. Drop the flag and build to the default DerivedData (see CLAUDE.md)." >&2
  exit 2
fi
exit 0
