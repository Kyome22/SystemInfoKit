---
name: add-language
description: Add a new language to SystemInfoKit. Use when the user asks to add localization for a language ("Italian に対応させたい", "add Portuguese", "support Thai localization", "新規言語追加", "add locale"). Codifies the exact 5-file recipe — Language.swift enum + Localizable.xcstrings + ByteDataTests + PercentageTests + README — with translation generation, locale-identifier verification, and a build+test verification pass.
---

# Add a new language to SystemInfoKit

This skill codifies every step required to add a new language to SystemInfoKit. It exists because the recipe touches 5 files in 3 directories with no CI to catch omissions — a missed key in `.xcstrings` silently falls back to English at runtime.

Only these files change:

1. `Sources/SystemInfoKit/Entities/Language.swift`
2. `Sources/SystemInfoKit/Resources/Localizable.xcstrings`
3. `Tests/SystemInfoKitTests/EntityTests/ByteDataTests.swift`
4. `Tests/SystemInfoKitTests/EntityTests/PercentageTests.swift`
5. `README.md`

**Do not** edit `Package.swift`, any `Repository`, any `*Info`, `SystemInfoObserver.swift`, or `Localizable.swift`.

---

## Step 0 — Gather 4 required inputs

Ask the user (or infer from their message and confirm) these four values before touching any file:

| Variable | Example | Notes |
|----------|---------|-------|
| Language name (English, capitalized) | `Italian` | Used in README's "Supported languages" list |
| Enum case name | `italian` | lowerCamelCase; must sort alphabetically among existing cases (`chineseSimplified` / `chineseTraditional` / `english` / `french` / `german` / `japanese` / `korean` / `russian` / `spanish` / `vietnamese`) |
| `Locale` initializer | `Locale(languageCode: .italian)` | Pick one form:<br>• `Locale(languageCode: .xxx)` — most languages<br>• `Locale(languageCode: .chinese, script: .hanSimplified)` — scripts<br>• `Locale(languageCode: .portuguese, script: nil, languageRegion: .brazil)` — regional variants |
| Locale identifier | `it` | The **runtime value** of `<the Locale>.identifier`. Xcstrings uses this string as the block key, and SPM emits the compiled `.lproj` folder with this name. Verify it against Step 1's `Locale`. |

**Pitfall — identifier verification is not optional.** If the identifier does not match what `Locale(...).identifier` actually returns, the `.xcstrings` translations will be compiled into the wrong `.lproj` and never surface at runtime. Verify with the one-liner in Step 6's Verification section before proceeding to Step 2.

Existing coverage — do not duplicate:

- Language cases: chineseSimplified, chineseTraditional, english, french, german, japanese, korean, russian, spanish, vietnamese.
- Xcstrings locales: `de`, `en`, `es`, `fr`, `ja`, `ko`, `ru`, `vi`, `zh-Hans`, `zh-Hant`.

---

## Step 1 — Edit `Sources/SystemInfoKit/Entities/Language.swift`

Two edits, both in the same `enum Language`:

**1a. Add the case** in the `enum` body (lines 3–15), preserving alphabetical order. For a new `.italian`, it goes between `.german` and `.japanese`:

```swift
case german
case italian    // ← new
case japanese
```

**1b. Add the `switch` arm** in the `var locale: Locale` block (lines 16–41), same alphabetical position:

```swift
case .german:
    Locale(languageCode: .german)
case .italian:
    Locale(languageCode: .italian)   // ← new; use the exact initializer from Step 0
case .japanese:
    Locale(languageCode: .japanese)
```

**Do not** modify `var bundle: Bundle?` (lines 43–49) — its `Bundle.module.path(forResource: locale.identifier, ofType: "lproj")` lookup is generic.

---

## Step 2 — Edit `Sources/SystemInfoKit/Resources/Localizable.xcstrings`

For every one of the 25 keys, add a new localization block keyed by the identifier from Step 0. The reference table for all keys lives in `references/keys.md` — load it before generating translations.

Block shape (add alongside the existing `de` / `en` / … blocks; xcstrings does not require alphabetical ordering of locales, but match the existing style):

```json
"<locale-id>" : {
  "stringUnit" : {
    "state" : "translated",
    "value" : "<translated text>"
  }
}
```

Rules:

- **All 25 keys must be filled.** Missing keys fall back to English silently.
- **`state` must be `"translated"`.** Not `"new"`, not `"needs_review"` — Xcode's String Catalog editor uses these, but the runtime only cares that the value exists; the state field is preserved so tools like the Xcode editor treat the entry as complete.
- **Preserve every format specifier.** `%@` and `%lld` must appear in every translated value that had them in the English source. Only their position may move if grammar requires.
- **Follow typographic conventions of the target language** — see `references/keys.md` "Translation policy" section for the observed per-language conventions (fr uses ` : `, ja uses `：`, most others `: `).

Generate translations in this order:

1. Read `references/keys.md` for the 25 key list and format constraints.
2. Read a few existing entries from a linguistically similar language (e.g. for Italian, look at the existing `fr` and `es` blocks) to match the punctuation convention.
3. Produce all 25 translations at once in a single message, formatted as `key → value` pairs, and ask the user to confirm before writing the file.
4. Only after confirmation, edit the xcstrings file.

Editing approach for the xcstrings file: prefer `Edit` (or many small `Edit` calls) over `Write` — the file is large JSON and a full rewrite risks reordering or reformatting existing entries.

---

## Step 3 — Edit `Tests/SystemInfoKitTests/EntityTests/ByteDataTests.swift`

Add one new element to the `@Test(arguments: [...])` array (lines 7–68), in alphabetical position by enum case name.

Field values are deterministic:

- `language`: the new enum case.
- `expectedValue`: **always `888.889`** — the numeric readable value produced by `MeasurementFormatter` for `888_888_888_888` bytes is the same across every existing locale, and the parse-back uses `numberStyle = .decimal` so locale decimal separators are handled by the formatter.
- `expectedUnit`: what `MeasurementFormatter(unitStyle:.short, unitOptions:.naturalScale)` produces for the locale on that byte count. Most languages emit `"GB"`. Known exceptions: `fr` → `"Go"`, `ru` → `"ГБ"`. **Verify** with the one-liner in Verification.
- `expectedDescription`: `"888.9 <unit>"` (period) or `"888,9 <unit>"` (comma) depending on the locale's decimal separator. Formed by `Percentage`-style formatting through the same locale — verify with the same one-liner.

Example new row for Italian (comma-decimal, `GB`):

```swift
.init(
    language: .italian,
    expectedValue: 888.889,
    expectedUnit: "GB",
    expectedDescription: "888,9 GB"
),
```

---

## Step 4 — Edit `Tests/SystemInfoKitTests/EntityTests/PercentageTests.swift`

Add one new element to the `@Test(arguments: [...])` array (lines 7–17), alphabetical position:

```swift
.init(language: .italian, expectedDescription: "88,9%"),
```

Decimal separator judgment (empirically confirmed for existing locales):

- Uses `.`: `en`, `ja`, `ko`, `zh-Hans`, `zh-Hant`.
- Uses `,`: `de`, `es`, `fr`, `ru`, `vi`.

For a new locale, verify with the one-liner in Verification — the CLDR data behind `Locale` occasionally surprises.

---

## Step 5 — Edit `README.md`

Add the language name (English, capitalized) to the bulleted "Supported languages" list (currently lines 119–130), in alphabetical position:

```markdown
- German
- Italian    ← new
- Japanese
```

---

## Step 6 — Verification

Run all four checks. Do not declare done until all pass.

### 6a. Confirm `Locale.identifier`, `MeasurementFormatter` output, decimal separator

Write and run this scratch program to lock down the values used in Steps 3 and 4. **Adapt the `Locale(...)` line to whatever Step 0 chose.**

```swift
// scratchpad/verify-locale.swift
import Foundation

let locale = Locale(languageCode: .italian)  // ← match Step 0
print("identifier:", locale.identifier)      // must equal the Step 0 identifier

let mf = MeasurementFormatter()
mf.locale = locale
mf.unitStyle = .short
mf.unitOptions = .naturalScale
let m = Measurement(value: 888_888_888_888, unit: UnitInformationStorage.bytes)
print("bytes readable:", mf.string(from: m)) // → expectedUnit + expectedDescription

let pct = String(format: "%.1f", locale: locale, 88.9)
print("percent format:", pct)                // "88.9" → '.'; "88,9" → ','
```

Run:

```bash
swift /path/to/verify-locale.swift
```

If `identifier:` does not match Step 0's identifier, fix Step 0 before proceeding — the xcstrings block will otherwise land under the wrong key.

### 6b. Build

```bash
swift build
```

Must succeed with no warnings introduced by the diff.

### 6c. Test the affected suites first, then the full suite

```bash
swift test --filter ByteDataTests
swift test --filter PercentageTests
swift test
```

If the two filtered runs fail, cross-check the actual `MeasurementFormatter` / `%.1f` output against your Step 6a scratch output — those are the truth.

### 6d. Repository tests (regression)

Repository tests (`BatteryRepositoryTests` etc.) hard-code English string expectations. They should stay green — if any fail, you inadvertently edited an English translation in `.xcstrings`. Revert that change.

---

## Non-goals — do NOT do these as part of a language addition

- Do NOT make `enum Language` `public`. It is intentionally internal — the public API always uses `.automatic`. Changing this is a separate API design task.
- Do NOT edit `Sources/SystemInfoKit/Entities/Values/Temperature.swift`. The `°C` unit is currently hard-coded; localizing it (e.g., Fahrenheit for `en-US`) is a separate feature.
- Do NOT edit `Package.swift`. Resources are auto-processed via `.process("Resources")`.
- Do NOT add CI, lint, or translation-completeness scripts. That's a separate infrastructure task.
- Do NOT edit `Repositories/`, `Entities/Info/`, `SystemInfoObserver.swift`, or `Localizable.swift`.

---

## Done criteria (for the assistant to self-check before reporting completion)

- [ ] `Language.swift` has exactly 2 new lines (one `case`, one `switch` arm).
- [ ] `Localizable.xcstrings` has the new locale block on all 25 keys, `state: "translated"`.
- [ ] `ByteDataTests.swift` and `PercentageTests.swift` each gained exactly one `.init(...)` row.
- [ ] `README.md` "Supported languages" list gained exactly one bullet.
- [ ] `swift build` clean, `swift test` all green.
- [ ] `Package.swift` unchanged (verify with `git diff Package.swift`).
- [ ] User has approved the 25 translations verbatim before the xcstrings edit.
