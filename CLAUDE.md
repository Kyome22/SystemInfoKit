# SystemInfoKit — Repository Guide

## What this is

A Swift Package that streams macOS/iOS system telemetry (CPU, memory, storage, battery, network) as an `AsyncStream<SystemInfoBundle>`. Consumers subscribe via a singleton, then start/stop monitoring at their own cadence.

- Public entry point: `Sources/SystemInfoKit/SystemInfoObserver.swift` (use `SystemInfoObserver.shared` — the initializer is intentionally `internal`).
- Public bundle: `Sources/SystemInfoKit/Entities/SystemInfoBundle.swift`.
- License: Apache-2.0.

## Build & test

```bash
swift build

# Use xcodebuild — NOT `swift test` — for the full test suite.
xcodebuild test \
  -scheme SystemInfoKit \
  -destination 'platform=macOS' \
  -skipPackagePluginValidation \
  -skipMacroValidation
```

- Test framework is **swift-testing** (`import Testing`, `@Test`, `#expect`, `#require`) — not XCTest.
- **Why `xcodebuild` and not `swift test`.** `swift build`/`swift test` from the CLI copies `Localizable.xcstrings` into the bundle but does not compile it into per-locale `.strings`. `Bundle.module` at test time therefore has no localized strings, and every `String(localized:)` call returns the key itself (e.g. `"batteryIsNotInstalled"` instead of `"Battery: Not Installed"`). All Repository suites fail as a result, on `main` too — it is an environmental issue, not a regression. Same rule applies to any Swift Package that ships `.xcstrings` or `.xcassets`. Fast pre-checks that only touch `MeasurementFormatter` / `%f` (e.g. `swift test --filter ByteDataTests`) still work under `swift test`.
- For iOS-guarded code (`#if os(iOS)` in `BatteryRepository`, `UIDeviceClient`, etc.), swap the destination to `'platform=iOS Simulator,name=<simulator>'`.
- There is no CI, lint config, formatter, or Makefile. Verification is entirely local.

## Platforms & Swift version

From `Package.swift`:

- Swift 6.2 (`// swift-tools-version: 6.2`)
- `.macOS(.v13)`, `.iOS(.v16)`
- `defaultLocalization: "en"`, `resources: [.process("Resources")]`
- Upcoming feature `ExistentialAny` enabled on both target and testTarget — always write `any SystemRepository`, `any CVarArg`, never bare protocol types.

## Architecture at a glance

Four cooperating patterns:

1. **Repository pattern.** Each `SystemInfoType` case is served by one `SystemRepository` conformer under `Sources/SystemInfoKit/Repositories/`. Protocol: `Sources/SystemInfoKit/Repositories/SystemRepository.swift`. Canonical example: `Sources/SystemInfoKit/Repositories/CPURepository.swift`. Standard idiom is `var result = XxxInfo(language: language)` + `defer { stateClient.withLock { $0.bundle.xxxInfo = result } }`.

2. **DI Client pattern** (pointfree-style). Every OS API is wrapped as a `struct XxxClient: DependencyClient` holding `@Sendable` closures with `liveValue` / `testValue`. Aggregated in `Dependencies` (`Sources/SystemInfoKit/Dependencies/Dependencies.swift`). Tests override fields via `testDependency(of: XxxClient.self) { $0.someClosure = { … } }`.

3. **Shared state.** All mutable state lives in `OSAllocatedUnfairLock<State>` behind `StateClient` (`Sources/SystemInfoKit/Dependencies/StateClient.swift`, `Sources/SystemInfoKit/Entities/State.swift`). Repositories read/mutate via `stateClient.withLock { ... }` — they never own state themselves.

4. **Localization via `Localizable` protocol.** `Sources/SystemInfoKit/Localizable.swift` wraps `String(localized:bundle:)`. Every repository and `*Info` conforms and carries a `language: Language`.

## Public vs internal surface

**Public:** `SystemInfoObserver`, `SystemInfoBundle`, `SystemInfoType`, `SystemInfo`, the five `*Info` structs, `Percentage`, `ByteData`, `Temperature`, `NetworkInterface`, `DependencyClient` + `testDependency` helper. Mutable fields on models are `public internal(set) var` so consumers can read but only repositories can write.

**Internal (intentionally):** everything under `Dependencies/`, `Repositories/`, `State`, `Language`, `Localizable`, and all `SystemInfoObserver` initializers except access through `.shared`.

## Testing conventions

- `struct XxxTests { @Test func … }` — swift-testing.
- Parameterized via `@Test(arguments: [...])` — see `Tests/SystemInfoKitTests/EntityTests/PercentageTests.swift`.
- `@testable import SystemInfoKit` for internal access.
- Fixture pattern: build `OSAllocatedUnfairLock<State>`, seed it via `withLock`, then construct the SUT with `.testDependencies(...)` + per-field overrides + `.testDependency(state)`.
- Repository tests always use `language: .english` for deterministic string expectations.
- `Tests/SystemInfoKitTests/RepositoryTests/NetworkRepositoryTests.swift` has an inline `NRMock` that fabricates raw `ifaddrs` C structs — the only place raw C pointer fixtures appear.

## Adding a language

Follow `.claude/skills/add-language/SKILL.md` — 5 files change (`Language.swift`, `Localizable.xcstrings`, `ByteDataTests`, `PercentageTests`, `README.md`) and none other. The skill also generates translations and produces a verification checklist.

## Non-obvious gotchas

- **`SystemInfoObserver.init()` is `internal`.** Consumers must go through `SystemInfoObserver.shared`. The two-argument init is for tests only.
- **`Language` is `internal`.** The public API always runs `.automatic` (system locale). Adding a language does NOT expose the case to consumers.
- **`systemInfoStream()` is single-consumer** (`bufferingPolicy: .bufferingNewest(1)`). Multiple `for await` loops steal from each other. README documents the fix: wrap with `swift-async-algorithms`' `share()` on the consumer side; the package intentionally does not depend on it.
- **`monitorInterval` is clamped to `max(interval, 1.0)`** in `SystemInfoObserver.startMonitoring`.
- **`toggleActivation` re-emits immediately.** Newly enabled types get a zero-placeholder `*Info` right away; newly disabled types get `nil`; unchanged types are untouched.
- **Two singletons.** `SystemInfoObserver.shared` and `StateClient.liveValue` are independent. A hand-built `SystemInfoObserver(dependencies: .init(), language: ...)` still shares state with `.shared` unless the test also overrides `stateClient`.
- **Battery has a macOS 27+ / pre-27 split** in `Sources/SystemInfoKit/Repositories/BatteryRepository.swift` (`BatteryData` dict + `AppleSmartBatteryPack` on 27+, flat keys + `AppleRawMaxCapacity` before). `update_with_battery` feeds both key sets at once and picks values that yield the same `description` either way, so the suite passes whatever the host runs — but the branch not taken by the host is never exercised. `getMatchingService` also returns one dictionary regardless of the service name, so `AppleSmartBattery` and `AppleSmartBatteryPack` are not distinguished.
- **Real-device dumps live in `MeasuredValues/`** — the evidence behind that split, contributed per machine and macOS version. `MeasuredValues/KeyMatrix.md` shows which key exists where; `MeasuredValues/README.md` explains the naming and the pruning. Consult them before assuming a key is available on every machine: `AdapterDetails.Name` in particular is missing both when unplugged and when the PMU cannot identify the charger.
- **`adapterName` is a display string, not a raw IOKit value.** `BatteryRepository` gates it on `ExternalConnected` and falls back `AdapterDetails.Name` → `AdapterDetails.Watts` (as the localized `batteryAdapter%lld`) → `batteryUnknown`, so `adapterName == nil` means exactly "running on battery". `powerSource` no longer looks at `isCharging` — plugged in but not charging still shows the adapter, which is what 5 of the 11 dumps in `MeasuredValues/` are. Note `Watts` is the negotiated PD wattage, not the adapter's rating (a 96W adapter reports 94).
- **`maxCapacity` does not reproduce System Settings, and no key in `AppleSmartBattery` can.** Two machines were measured against their System Settings reading — M1 Pro at 91% and M4 Pro at 97% — and the numerator needed to produce those against `DesignCapacity` (5498-5559 and 6030-6093) appears nowhere in either dump. No ratio of any two keys lands on them either. `NominalChargeCapacity` is not the answer: it sits a near-constant +2.4 to +2.8 points above `AppleRawMaxCapacity` on all nine dumps, so it cannot fix an error that is +2.9 on one machine and -4.2 on the other. Summed error is 7.13 for the raw figure against 7.16 for the nominal one — a dead heat. macOS is most likely displaying a smoothed or cached figure rather than a live gauge reading. `AppleRawMaxCapacity / DesignCapacity` stays because it is what coconutBattery reports and there is no evidence for anything better. **Switching this key has repeatedly drawn "the battery info is wrong" reports in the past** — inevitably, since neither candidate matches System Settings, so changing it only swaps which users notice. Treat switching as needing new measurements, not reasoning. Nor would `NominalChargeCapacity` tidy anything: it sits at the top level pre-27 and under `BatteryData` on 27, exactly like the current pair, so the `if #available` stays either way — and it clamps on 3 of 11 dumps against 1, collapsing three distinguishable machines to a flat 100.0%. (`AppleRawMaxCapacity` equals `BatteryData.FccComp2` on eight of nine dumps — same quantity under two names.)
- **The macOS 27+ `percentage` deliberately has no `min(…, 1)`** — `BatteryData.CurrentCapacity` is the system's own value there and cannot exceed 100, unlike the pre-27 ratio. The clamp on `maxCapacity` does earn its keep: a 5-cycle M5 reports `AppleRawMaxCapacity` above `DesignCapacity` (101.6%).
- **Intel Macs are out of scope.** Every dump in `MeasuredValues/` is Apple Silicon and that is fine; do not add Intel-specific handling on speculation.
- **`Temperature` is hard-coded to `°C`** — no Fahrenheit / locale awareness.
- **`Percentage.width`** (default 4, batteries use 5) is a formatting concern threaded through the model; changing it shifts golden strings in README and repo tests.
- **`_description` on `SystemInfo`** is intentionally accessible package-wide despite the underscore — `BatteryInfo` uses it to compose `description` conditionally on `isInstalled`.
- **`String.separate()`** in `Sources/SystemInfoKit/Extensions/String+Extension.swift` uses `RegexBuilder` to split localized byte strings (`"1,5 Go"` / `"1.5 GB"`) for alignment — that's why comma-decimal locales work end-to-end.
- **`.swiftpm/` is git-ignored but currently checked in** for the workspace stub. Don't rely on its contents.
- **`PrivacyInfo.xcprivacy`** ships in resources — any change to which SPIs the package reads (IOKit properties, `getifaddrs`, etc.) should be reflected there.

## Where things live

```
Sources/SystemInfoKit/
├── SystemInfoObserver.swift        Public façade (singleton).
├── Localizable.swift               Internal L10n protocol.
├── Dependencies/                   DI container + typed clients (Host, IOKit, NWPathMonitor, POSIX, State, UIDevice, URLResourceValues).
├── Entities/
│   ├── SystemInfoBundle.swift      Public aggregate.
│   ├── SystemInfoType.swift        Public enum + repositoryType map.
│   ├── State.swift                 Internal mutable state.
│   ├── Language.swift              Internal locale + bundle lookup.
│   ├── Info/                       Public *Info structs (CPU/Memory/Storage/Battery/Network) + SystemInfo protocol.
│   └── Values/                     Public value types (Percentage, ByteData, Temperature, DataTraffic, NetworkInterface).
├── Extensions/String+Extension.swift  RegexBuilder split for "1.5 GB".
├── Repositories/                   One per SystemInfoType.
└── Resources/                      Localizable.xcstrings + PrivacyInfo.xcprivacy.

Tests/SystemInfoKitTests/
├── SystemInfoObserverTests.swift
├── EntityTests/                    ByteData, Percentage.
└── RepositoryTests/                One per repository.

MeasuredValues/                     Reference data only — not built, not bundled.
├── AppleSmartBattery/              <Model>_macOS_<Major>_<State>.json per contributed machine.
├── AppleSmartBatteryPack/          Same, for the pack service (macOS 27+ temperature).
├── KeyMatrix.md                    Which key exists where — generated.
└── normalize.py                    Tree dump -> JSON, and --matrix.
```
