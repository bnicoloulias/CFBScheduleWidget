#!/bin/bash
# PostToolUse/Write|Edit: format edited Swift files with the repo's .swift-format.
f=$(jq -r '.tool_response.filePath // .tool_input.file_path // empty')
case "$f" in
  *.swift) [ -f "$f" ] && xcrun swift-format format --in-place "$f" ;;
esac
exit 0
