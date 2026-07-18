# SystemInfoKit — Repository Guide

## What this is

A Swift Package that streams macOS/iOS system telemetry (CPU, memory, storage, battery, network) as an `AsyncStream<SystemInfoBundle>`. Consumers subscribe via a singleton, then start/stop monitoring at their own cadence.

- Public entry point: `Sources/SystemInfoKit/SystemInfoObserver.swift` (use `SystemInfoObserver.shared` — the initializer is intentionally `internal`).
- Public bundle: `Sources/SystemInfoKit/Entities/SystemInfoBundle.swift`.
- License: Apache-2.0.

## Build & test

```bash
swift build
swift test
```

- Test framework is **swift-testing** (`import Testing`, `@Test`, `#expect`, `#require`) — not XCTest.
- `swift test` on macOS only exercises the macOS branch. iOS-guarded code (`#if os(iOS)` in `BatteryRepository`, `UIDeviceClient`, etc.) needs `xcodebuild -destination 'platform=iOS Simulator,name=<simulator>'`.
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
- **Battery has a macOS 27+ / pre-27 split** in `Sources/SystemInfoKit/Repositories/BatteryRepository.swift` (`BatteryData` dict + `AppleSmartBatteryPack` on 27+, flat keys + `AppleRawMaxCapacity` before). Tests only cover the pre-27 branch.
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
```
