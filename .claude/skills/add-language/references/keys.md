# Localizable.xcstrings — Key Reference

Source of truth: `Sources/SystemInfoKit/Resources/Localizable.xcstrings` (25 keys, `sourceLanguage: "en"`).

Every key below must be present under a new locale, with `state: "translated"`. Keep the format specifiers (`%@`, `%lld`) exactly as in the English source — reorder them within the sentence only if the target language requires it.

## Category: Battery

| Key | English source | Placeholder meaning |
|-----|----------------|---------------------|
| `battery` | `Battery` | — |
| `battery%@` | `Battery: %@` | `%@` = percentage like `"98.2%"` / `"98,2%"` |
| `batteryIsNotInstalled` | `Battery: Not Installed` | — |
| `batteryUnknown` | `Unknown` | — |
| `batteryPowerSource%@` | `Power Source: %@` | `%@` = raw source name (usually English, do not localize the placeholder) |
| `batteryMaxCapacity%@` | `Max Capacity: %@` | `%@` = percentage |
| `batteryCycle%lld` | `Cycle Count: %lld` | `%lld` = integer cycle count |
| `batteryTemperature%@` | `Temperature: %@` | `%@` = temperature string, currently hard-coded `"30.2°C"` format |

## Category: CPU

| Key | English source | Placeholder meaning |
|-----|----------------|---------------------|
| `cpu%@` | `CPU: %@` | `%@` = percentage |
| `cpuSystem%@` | `System: %@` | `%@` = percentage |
| `cpuUser%@` | `User: %@` | `%@` = percentage |
| `cpuIdle%@` | `Idle: %@` | `%@` = percentage |

## Category: Memory

| Key | English source | Placeholder meaning |
|-----|----------------|---------------------|
| `memory%@` | `Memory: %@` | `%@` = percentage |
| `memoryPressure%@` | `Pressure: %@` | `%@` = percentage |
| `memoryApp%@` | `App Memory: %@` | `%@` = byte string like `"6.4 GB"` |
| `memoryWired%@` | `Wired Memory: %@` | `%@` = byte string. **Apple-UI cross-check strongly recommended** — this is technical macOS jargon (kernel-reserved memory that can't be swapped) and existing translations vary widely (de: `Reservierter Speicher`, es: `Memoria física`, fr: `Mémoire résidente`, ja: `確保されているメモリ`, tr: `Kablolu Bellek`). Follow whatever Apple's Activity Monitor uses in the target language rather than translating literally. |
| `memoryCompressed%@` | `Compressed: %@` | `%@` = byte string |

## Category: Storage

| Key | English source | Placeholder meaning |
|-----|----------------|---------------------|
| `storage%@` | `Storage: %@ used` | `%@` = percentage; the word `used` is a suffix that gets translated |

## Category: Network

| Key | English source | Placeholder meaning |
|-----|----------------|---------------------|
| `network%@` | `Network: %@` | `%@` = interface name (`"Ethernet"`, `"Wi-Fi"`, etc. — keep English if the term is universally understood) |
| `networkCellular` | `Cellular` | — |
| `networkUnknown` | `Unknown` | — |
| `networkNoConnection` | `No Connection` | — |
| `networkLocalIP%@` | `Local IP: %@` | `%@` = IP string |
| `networkUpload%@` | `Upload: %@/s` | `%@` = byte string. Existing translations keep `/s` as-is (not localized) |
| `networkDownload%@` | `Download: %@/s` | Same as upload |

## Translation policy (observed from existing locales)

Follow target-language typographic conventions inside the value. Verified samples:

- **French (`fr`)** uses ` : ` — ASCII colon with a space on **both** sides (e.g. `Batterie : %@`, `Envoi : %@/s`).
- **Japanese (`ja`)** uses `：` — the full-width colon with no surrounding space (e.g. `バッテリー：%@`).
- **Russian (`ru`)**, **English (`en`)**, **German (`de`)**, **Spanish (`es`)**, **Korean (`ko`)**, **Vietnamese (`vi`)**, **Chinese Simplified/Traditional (`zh-Hans` / `zh-Hant`)** use `: ` — ASCII colon + single trailing space.

Before writing a new locale's translations, **grep existing entries with the same or similar-family language** to match the convention (e.g. for Italian look at `fr` / `es`; for Portuguese look at `es` / `fr`; for Thai / Indonesian check what conventions Apple's own String Catalog defaults show).

Other rules:

- **`/s` in Upload/Download**: Not translated in any existing locale (fr keeps `Envoi : %@/s`, ru keeps `Выгрузка: %@/s`, ja keeps `アップロード：%@/s`). Keep the literal `/s`.
- **`Unknown`**: `batteryUnknown` and `networkUnknown` are separate keys with the same English source; translate independently (they may share a translation).
- **`Battery: Not Installed` vs `Battery: %@`**: `batteryIsNotInstalled` is a full standalone sentence — do NOT try to reuse `battery%@` interpolated with "Not Installed".
- **Placeholder position**: If the target grammar requires reordering, keep the `%@` / `%lld` specifier itself intact — only its position in the sentence may move.
