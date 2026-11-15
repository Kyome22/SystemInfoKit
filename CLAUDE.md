# SystemInfoKit — Repository Guide

A Swift Package that streams macOS/iOS system telemetry (CPU, memory, storage, battery, network) as an `AsyncStream<SystemInfoBundle>`. Consumers go through `SystemInfoObserver.shared` and start/stop monitoring at their own cadence.

## Build & test

```bash
xcodebuild test \
  -scheme SystemInfoKit \
  -destination 'platform=macOS' \
  -skipPackagePluginValidation \
  -skipMacroValidation
```

- **Use `xcodebuild`, not `swift test`.** The CLI does not compile `Localizable.xcstrings` into per-locale strings, so every `String(localized:)` returns its key and all Repository suites fail, on `main` too. `swift test --filter ByteDataTests` and other suites that never hit localized strings still work as quick checks.
- For iOS-only code (`#if os(iOS)` in `UIDeviceClient`), build for `'generic/platform=iOS Simulator'` as well.
- There is no CI, linter, or formatter. Verification is entirely local.
- `ExistentialAny` is enabled on both targets — always write `any SystemRepository`, never a bare protocol type.

## Architecture

1. **Repositories.** Each `SystemInfoType` case is served by one `SystemRepository` under `Sources/SystemInfoKit/Repositories/`; `CPURepository` is the canonical example. The idiom is `var result = XxxInfo(language: language)` plus `defer { stateClient.withLock { $0.bundle.xxxInfo = result } }`.
2. **DI clients.** Every OS API is wrapped in a `struct XxxClient: DependencyClient` of `@Sendable` closures with `liveValue` / `testValue`, aggregated in `Dependencies`. Clients hold no state of their own: they take the object they operate on as an argument (`NWPathMonitor`, `URLResourceValues`, …).
3. **Shared state.** All mutable state lives in `State` behind `StateClient`, whose `withLock` runs the body under the lock. Repositories read and mutate it only through `stateClient.withLock`. Bodies must not call `withLock` again — the unfair lock traps on reentry.
4. **Localization.** Every repository and `*Info` conforms to `Localizable` and carries a `language: Language`.

`Dependencies/`, `Repositories/`, `State`, `Language`, `Localizable`, and every `SystemInfoObserver` initializer are internal on purpose. Model fields are `public internal(set) var`.

## Testing conventions

- swift-testing (`@Test`, `#expect`, `#require`), not XCTest.
- Fixture pattern: build an `OSAllocatedUnfairLock<State>`, seed it with `withLock`, and construct the SUT with `.testDependencies(...)`, per-field overrides, and `.testDependency(state)`.
- Repository tests use `language: .english` for deterministic strings.

## Adding a language

Follow `.claude/skills/add-language/SKILL.md`.

## Non-obvious gotchas

- **`Language` is internal.** The public API always runs `.automatic`, so adding a language never exposes a case to consumers.
- **`systemInfoStream()` is single-consumer** (`.bufferingNewest(1)`). Multiple `for await` loops steal from each other. The README points consumers to `swift-async-algorithms`' `share()`; the package intentionally does not depend on it.
- **`SystemInfoObserver.shared` and `StateClient.liveValue` are separate singletons.** A hand-built `SystemInfoObserver(dependencies: .init(), …)` still shares state with `.shared` unless the test overrides `stateClient`.
- **Each `startMonitoring` creates a fresh `NWPathMonitor`**, kept in `State.pathMonitor`. A cancelled monitor never delivers another path, so it must not be reused. `startMonitoring` and `stopMonitoring` run entirely inside `monitoringTask.withLock`; take that lock before the state lock, never the other way round.
- **Storage free space reads `volumeAvailableCapacityForImportantUsageKey` on purpose** — it is the figure Finder and System Settings show. Do not swap it for `volumeAvailableCapacityKey`, which leaves out purgeable space. The key costs 10+ ms per read, which is why `StorageRepository` caches it in `State.storageCapacitySnapshot`.
- **Battery has a macOS 27+ / pre-27 split** in `BatteryRepository`. `update_with_battery` feeds both key sets at once, so the branch the host does not take is never exercised, and the `getMatchingService` stub does not tell `AppleSmartBattery` from `AppleSmartBatteryPack`.
- **`MeasuredValues/` holds real-device IOKit dumps** — the evidence for every battery key choice. Check `MeasuredValues/KeyMatrix.md` before assuming a key exists on every machine.
- **Leave the battery capacity key alone.** No key reproduces the Battery Health percentage in System Settings, and switching keys has drawn "the battery info is wrong" reports before. `MeasuredValues/README.md` has the measurements.
- **The macOS 27+ `percentage` has no `min(…, 1)` on purpose**, because `BatteryData.CurrentCapacity` cannot exceed 100. The clamp on `maxCapacity` is needed: new batteries report above `DesignCapacity`.
- **`adapterName == nil` means exactly "running on battery".** Plugged in but not charging still shows the adapter. `AdapterDetails.Watts` is the negotiated wattage, not the adapter's rating.
- **Intel Macs are out of scope.** Do not add Intel-specific handling on speculation.
- **`Percentage.width`** (default 4, batteries 5) feeds the golden strings in the README and the repository tests.
- **`_description` on `SystemInfo`** is package-wide despite the underscore; `BatteryInfo` builds `description` from it.
- **`PrivacyInfo.xcprivacy`** must be updated whenever the set of required-reason APIs the package reads changes.
