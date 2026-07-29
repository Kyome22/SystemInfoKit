# Measured Values

Real-device dumps of the IOKit services that `BatteryRepository` reads, contributed by volunteers.

`AppleSmartBattery` and `AppleSmartBatteryPack` expose different keys depending on the macOS version and the machine.
macOS 27, for example, dropped the top-level `AppleRawMaxCapacity` and `Temperature` keys and moved the equivalent data into the `BatteryData` sub-dictionary — which is why `Sources/SystemInfoKit/Repositories/BatteryRepository.swift` carries a macOS 27+ / pre-27 split.
These dumps are the evidence behind that split, and the reference for any key SystemInfoKit may want to support later.

They are reference data only: nothing here is compiled, bundled, or read at runtime.

## Layout

```
MeasuredValues/
├── AppleSmartBattery/<Model>_macOS_<Version>.json
├── AppleSmartBatteryPack/<Model>_macOS_<Version>.json
├── KeyMatrix.md      Which key exists on which machine — generated
└── normalize.py      Dump -> JSON converter
```

`<Version>` uses underscores for the minor component, so macOS 26.4 becomes `macOS_26_4`.
Machines without a battery (`Mac_mini_M4`, `Mac_Studio_M4_Max`) are kept on purpose — they are the `BatteryInstalled == 0` case.

## Contributing a dump

Run this on the machine to collect, and save the output as `<Model>_macOS_<Version>.json`:

```bash
ioreg -arw0 -c AppleSmartBattery     | plutil -convert json -r -o - -
ioreg -arw0 -c AppleSmartBatteryPack | plutil -convert json -r -o - -
```

This is preferred over the `ioreg` tree output that the original dumps used: types, arrays, and array indices all survive intact.
**Remove `Serial`, `SerialString`, `MfgData`, `ManufacturerData`, and `LifetimeData.Raw` before opening a pull request** — they identify your specific machine and are of no use here.

If you only have a tree-shaped dump, drop the `.txt` next to the JSON files and run:

```bash
python3 MeasuredValues/normalize.py         # <name>.txt -> <name>.json
python3 MeasuredValues/normalize.py --matrix  # regenerate KeyMatrix.md
```

The converter needs nothing but Python 3 from the standard macOS toolchain.

## What was removed

The dumps were pruned once, when they were converted from tree output to JSON.
The originals are committed verbatim in git history — `git log --diff-filter=D -- 'MeasuredValues/**/*.txt'` finds the commit that removed them — so nothing here is unrecoverable.

Subtrees dropped whole, none of which describe the battery:

| Key | Why |
| --- | --- |
| `PortControllerInfo` | USB-C PD port controller diagnostic counters. 42% of the original volume on its own |
| `FedDetails` | PD partner-device descriptors. Zero in every dump collected |
| `AppleRawAdapterDetails` | Duplicate of `AdapterDetails` |
| `DeadBatteryBootData` | SMC boot management counters |
| `IOReportLegend` | IOReport channel definitions, not measurements |
| `IOGeneralInterest` | `"IOCommand is not serializable"` in every dump |
| `IOReportLegendPublic` | Constant `1` |

Everything else was kept, including subtrees SystemInfoKit does not read yet — `ChargerData`, `PowerTelemetryData`, `PowerDistribution`, `PowerOutDetails`, `CarrierMode`, and the full `AdapterDetails` with its `UsbHvcMenu` PD profile list.

Values under `Serial`, `SerialString`, `MfgData`, `ManufacturerData`, and `LifetimeData.Raw` are replaced with `"<redacted>"`.
The keys themselves stay, so a key disappearing in a newer macOS is still visible in `KeyMatrix.md`.
`DeviceName` (the gas gauge IC part number, e.g. `bq40z651`) is not machine-identifying and is kept.

Opaque binary values become `"<data: N bytes>"`. The byte content was unusable as text; the length is retained because it still distinguishes one OS version's layout from another.

## Known limits of the converted dumps

The tree format these were converted from does not distinguish a single-element array from a scalar, so `["4229"]` and `"4229"` both became `4229`.
Multi-element arrays are unaffected, and no dump collected so far contains a string-valued array where this could hide a dictionary.
Dumps contributed as plist per the instructions above do not have this problem at all.
