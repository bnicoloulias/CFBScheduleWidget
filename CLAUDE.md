# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

See [README.md](README.md) for setup and [ARCHITECTURE.md](ARCHITECTURE.md) for
how the code is shaped. Where either disagrees with the code, trust the code.

## Build and test

```sh
xcodegen generate   # after any project.yml change
xcodebuild -project CollegeFootballSchedule.xcodeproj -scheme "CollegeFootballSchedule" \
  -destination 'platform=macOS,arch=arm64' build   # or: test
```

Single test: append `-only-testing:CollegeFootballScheduleTests/<Suite>/<testName>`.
Tests use Swift Testing (`import Testing`, `@Test`), not XCTest.

Formatting is swift-format from the Xcode toolchain (`xcrun swift-format`,
config in `.swift-format`); a hook formats each edited `.swift` file. Lint with
`xcrun swift-format lint --recursive App Shared Widget Tests`.

## Never pass `-derivedDataPath`

Every build registers its product with LaunchServices, so each distinct output
path leaves another registered copy of
`com.bobbynicoloulias.CollegeFootballSchedule.Widget`. macOS does not prefer the newest,
and a widget already on the desktop stays bound to whichever copy it was added
from — it can run months-old code that no rebuild dislodges, and it looks
exactly like a bug in the change you just made. Moving the path (e.g. to
`/tmp`) doesn't help; only building to the one default location does, because
then CLI and Xcode builds replace each other. A hook blocks the flag.

## When the widget ignores a code change

Rule out duplicate registrations before touching the code:

```sh
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister \
  -dump | grep "path:" | grep -o "/.*CollegeFootballScheduleWidget.appex" | sort -u
```

One line is healthy. To tell which copy is stale, check whether its product
contains the change — for an AppIntent:
`grep -c YourIntentName "<appex>/Contents/Resources/Metadata.appintents/extract.actionsdata"`.
Recovery must `lsregister -u` before deleting files (the registration outlives
them); `/refresh-widget` runs the full procedure.

Separately, `chronod` caches each widget descriptor keyed on the bundle version,
which is pinned in `project.yml`. **Whenever you change a widget's name,
description, configuration type, or intents, bump `CURRENT_PROJECT_VERSION` in
`project.yml` yourself**, rebuild, and `killall chronod`. Don't edit chronod's
SQLite store.

`killall chronod`, `killall Dock NotificationCenter`, and `lsregister -u` on
stale copies are fine to run without asking.

## Project generation

`project.yml` is the source of truth. `CollegeFootballSchedule.xcodeproj`, both
`Info.plist`s and both `.entitlements` files are generated and gitignored — edit
`project.yml`, never those (a hook blocks it). `App/`, `Shared/`, `Widget/` are
included wholesale: new source files need no config change, but stray
non-source files get swept into the target, so keep scratch files out.

There is deliberately no App Group: signing is ad-hoc, and an App Group needs a
real team ID. The app and widget each keep their own cache.

## Code placement

- Logic that needs tests goes in `Shared/`; the test bundle is hosted by the app
  and can't reach extension types (`Shared/Models/WidgetRefreshPolicy.swift` is
  the example).
- Widget previews exist twice. `Widget/WidgetPreviews.swift` holds real
  `#Preview(as:)` WidgetKit previews, iOS-only: they render only with an
  iPhone destination in the canvas, because macOS can't host a widget preview
  ("This platform does not support previewing widgets"). Mac layouts are
  previewed as plain views from `App/Previews/WidgetLayoutPreviews.swift`.
  Preview-only helpers both use (`PreviewLogos`) go in `Shared/Previews/`.
- Log with `os.Logger` (subsystem `com.bobbynicoloulias.CollegeFootballSchedule`), not
  `print`. To see widget-process output, run the `CollegeFootballScheduleWidget`
  scheme and pick CollegeFootballSchedule as the host app.
