---
name: refresh-widget
description: Diagnose and fix a desktop widget that keeps running old code or shows a stale name/config after a rebuild. Checks for duplicate LaunchServices registrations, unregisters stale copies, bumps the build number if the descriptor changed, and restarts chronod.
disable-model-invocation: true
---

Get the CollegeFootballSchedule widget running the current code. Extra context from the
user: $ARGUMENTS

Work through these in order and report what you found at each step.

1. **Build to the default location** (never `-derivedDataPath`):
   ```sh
   xcodebuild -project CollegeFootballSchedule.xcodeproj -scheme "CollegeFootballSchedule" \
     -destination 'platform=macOS,arch=arm64' build
   ```
   Note the built `.app` path (under `~/Library/Developer/Xcode/DerivedData/`).

2. **List registered widget copies:**
   ```sh
   LSREG=/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister
   "$LSREG" -dump | grep "path:" | grep -o "/.*CollegeFootballScheduleWidget.appex" | sort -u
   ```
   Also check `ls -dt ~/Library/Developer/Xcode/DerivedData/CollegeFootballSchedule-*`
   for extra DerivedData trees (a project/folder rename creates one).

3. **Remove each stale copy** — every path that isn't inside the build from
   step 1. If unsure which is stale, check whether the appex contains the
   change (e.g. `grep -c <IntentName> "<appex>/Contents/Resources/Metadata.appintents/extract.actionsdata"`).
   For each stale one, unregister *first*, then delete:
   ```sh
   "$LSREG" -u "/path/to/stale/CFB Schedule Widget.app"
   rm -rf /path/to/stale/build-dir
   ```
   Show the paths before `rm -rf` and never delete the current build.

4. **If the widget's name, description, configuration type, or intents
   changed** (check `git diff`/recent commits under `Widget/` and
   `Shared/Intents/`), bump `CURRENT_PROJECT_VERSION` in `project.yml`, run
   `xcodegen generate`, and rebuild.

5. **Restart chronod:** `killall chronod` (launchd restarts it). Confirm it
   re-read the version:
   ```sh
   sqlite3 ~/Library/Group\ Containers/group.com.apple.chronod/chronod/chrono.sql \
     "select version from ExtensionMetadata where bundleIdentifier like '%Widget%'"
   ```
   Read only — never write to this database.

6. **Hand off to the user:** they need to launch the app once, then remove and
   re-add the widget. A placed instance stays bound to the old registration, and
   one placed before a Static→AppIntent configuration change never migrates.
   If only the app icon is stale, `killall Dock NotificationCenter` instead.
