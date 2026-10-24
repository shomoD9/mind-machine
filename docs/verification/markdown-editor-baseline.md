# Mac capture baseline

`PillSelfTest` measures the existing Capture text surface without changing its layout, styles, formatting, storage or focus behavior. This implements only ticket 1 from `/workspace/research/markdown-editor.md` (25 October 2026). The later Markdown editor work remains separate.

The existing `native-ci` Mac build runs the probe inside the sandboxed app. Download its `pill-selftest` artifact and read `result.json` → `captureBaseline`. CI uses **Debug**, a shared macOS VM, and forced animation (Reduce Motion off). It establishes repeatability and input correctness; the research budgets propose **Release on an M1 Air/8 GB, macOS 14 and current OS**. Run that hardware comparison separately.

| Observation | Samples | Proposed budget | Boundary and limitation |
| --- | --- | --- | --- |
| Warm open to input | 100 | p95 ≤100 ms | Before the normal controller hotkey handler → first-line area inside the visible window, presented opacity >0, focused editable text view, first key accepted by view/model and `displayIfNeeded` completion. Does not wait for animation completion. Excludes Carbon/OS hotkey delivery. |
| Key dispatch | 1,000 per fixture | Custom processing p95 ≤2 ms/p99 ≤4 ms remains unmeasured | Before window `sendEvent` → return; includes AppKit input handling and existing app callbacks/RTF encoding. This total cannot isolate custom processing. |
| Key dispatch to draw proxy | 1,000 per fixture | p95 ≤33 ms/p99 ≤50 ms; no >100 ms typing stalls | Dispatch start → `displayIfNeeded` return. Excludes OS input queuing and compositor/scanout. A draw callback does not prove pixels displayed. |
| Terminated-process launch to input | 30 in manual rerun | p95 ≤500 ms | Python launcher monotonic timestamp → child's readiness timestamp. Includes process/loader/AppKit/model setup. Processes exit between samples; filesystem/OS caches stay warm. |
| Large insertion | One 1 MiB insertion | No paste budget proposed | `insertText` → draw completion; synthetic paste proxy without accessing the user's pasteboard. |

Fixtures are exact ASCII 1/10/100 KiB documents with short paragraphs and a separate 100 KiB paragraph. Each receives 1,000 synthetic `x` key events through the actual panel. Fixture restoration and initial caret positioning are outside the interval. AppKit/SwiftUI gets a run-loop turn between events, also outside the interval. View and model must retain every character. Sizes use binary KiB/MiB, explicitly recorded rather than an ambiguous KB label.

Every distribution retains ordered raw samples, count, nearest-rank p50/p95/p99, maximum, and >100 ms count. Proposed budget comparisons are observations; misses do not fail this measurement-only ticket. Missing samples, input loss, absent focus and loss of TextKit 2 fail the self-test. The live view's `textLayoutManager` must be non-nil before/after opens and throughout typing/insertion. The probe never reads the legacy `layoutManager` property, which could itself trigger fallback. See [Apple's TextKit guidance](https://developer.apple.com/documentation/appkit/textkit) and [text-view compatibility guidance](https://developer.apple.com/videos/play/wwdc2022/10090/).

Signposts `Capture open to input` and `Capture key to draw` use subsystem `dev.mindmachine.capture-baseline`, Points of Interest. Use Instruments Time Profiler/Hitches and high-frame-rate video on the target Mac to establish actual visible latency and isolate custom main-thread work. The synthetic events do not establish physical-key or IME latency.

## Repeat on a Mac

Build the unchanged app in Release with the existing project. The commands use an ad-hoc local development signature and a container-writable results directory, following the existing self-test isolation; no distribution credentials are needed.

```sh
xcodebuild -project native/MindMachine.xcodeproj -scheme MindMachineMac \
  -configuration Release -destination 'platform=macOS,arch=arm64' \
  -derivedDataPath /tmp/mm-capture-baseline CODE_SIGNING_ALLOWED=NO build

# Apply the same minimal sandbox signature as the existing CI self-test.
python3 - <<'PY'
import plistlib
from pathlib import Path
source = plistlib.loads(Path('native/Apps/Mac/Vault.entitlements').read_bytes())
flags = {key: source[key] for key in ['com.apple.security.app-sandbox', 'com.apple.security.network.client']}
Path('/tmp/mm-capture-baseline.entitlements').write_bytes(plistlib.dumps(flags))
PY
codesign --force --sign - --entitlements /tmp/mm-capture-baseline.entitlements \
  /tmp/mm-capture-baseline/Build/Products/Release/MindMachineMac.app

python3 native/Scripts/measure_capture_baseline.py \
  /tmp/mm-capture-baseline/Build/Products/Release/MindMachineMac.app \
  "$HOME/Library/Containers/com.statemachine.mindmachine/Data/tmp/capture-baseline"
```

The script waits for each of 30 cold processes to exit, then runs the 100 warm opens and four typing fixtures in one process. `baseline.json` combines the distributions; individual JSON and logs retain observations. A clock-epoch mismatch fails explicitly. `--cold-opens` changes only the manual cold sample count. Both app modes reuse the existing throwaway vault, isolated defaults, disabled notifications and disabled sync. Close other copies of the app first so hotkey registration and window focus have a controlled owner.

## Recorded measurements

Runtime measurements are pending the PR's first Mac CI run. This Linux workspace cannot execute AppKit. Cold Release and physical visible/custom-processing measurements require the manual run above and are not inferred from CI.
