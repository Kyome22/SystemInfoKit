# Measured Values

Real-device dumps of the IOKit services that `BatteryRepository` reads, contributed by volunteers.

`AppleSmartBattery` and `AppleSmartBatteryPack` expose different keys depending on the macOS version and the machine.
macOS 27, for example, dropped the top-level `AppleRawMaxCapacity` and `Temperature` keys and moved the equivalent data into the `BatteryData` sub-dictionary — which is why `Sources/SystemInfoKit/Repositories/BatteryRepository.swift` carries a macOS 27+ / pre-27 split.
These dumps are the evidence behind that split, and the reference for any key SystemInfoKit may want to support later.

They are reference data only: nothing here is compiled, bundled, or read at runtime.

## Layout

```
MeasuredValues/
├── AppleSmartBattery/<Model>_macOS_<Version>_<State>.json
├── AppleSmartBatteryPack/<Model>_macOS_<Version>_<State>.json
├── KeyMatrix.md      Which key exists on which machine — generated
└── normalize.py      Dump -> JSON converter
```

`<Version>` is the major macOS version only. No key difference has been observed between point releases;
every difference collected so far falls on a major boundary, macOS 26 against 27.

`<State>` records how the machine was powered when the dump was taken, because that decides how much of
`AdapterDetails` exists:

| State | Condition | `AdapterDetails` |
| --- | --- | --- |
| `appleAdapter` | `ExternalConnected == 1`, `AdapterDetails.AdapterID != 0` | 16-17 keys, including `Name`, `Manufacturer`, `Model` |
| `unknownAdapter` | `ExternalConnected == 1`, `AdapterDetails.AdapterID == 0` | 10-11 keys. `Watts` is there, `Name` is not |
| `onBattery` | `ExternalConnected == 0` | `FamilyCode` only |
| `noBattery` | `BatteryInstalled == 0` | `FamilyCode` only |

So `adapterName` comes back nil in two different situations, not one: unplugged, and plugged into a charger
the PMU could not identify. `AdapterDetails.Watts` survives the second case and `Name` does not.

An `AppleSmartBatteryPack` dump carries the state of its `AppleSmartBattery` counterpart, so the two files
of one capture session keep the same name.

Machines without a battery (`Mac_mini_M4`, `Mac_Studio_M4_Max`) are kept on purpose — they are the
`BatteryInstalled == 0` case.

Two dumps sharing a model name are not necessarily the same machine. The two `MacBook_Pro_M4_Max_macOS_26`
dumps differ in `DesignCapacity` (8579 vs 6249 mAh), `ChemID` and `ManufactureDate` — they are the 16-inch
and the 14-inch configuration from two contributors.

## Contributing a dump

Run this on the machine to collect, and save the output as `<Model>_macOS_<Version>_<State>.json`
using the state table above:

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

**Please also note the Maximum Capacity percentage System Settings shows for the machine** (System Settings
> General > About > More Info, or Battery > Battery Health), and put it in the pull request description.
It cannot be recovered from the dump, and it is the only way to check what SystemInfoKit reports against
what macOS reports.

## System Settings comparison

Two dumps have a System Settings reading recorded against them.

| Dump | System Settings | `AppleRawMaxCapacity / DesignCapacity` | `NominalChargeCapacity / DesignCapacity` |
| --- | --- | --- | --- |
| `MacBook_Pro_M1_Pro_macOS_15_appleAdapter` | 91% | 93.89% (+2.9) | 96.36% (+5.4) |
| `MacBook_Pro_M4_Pro_macOS_26_unknownAdapter` | 97% | 92.77% (−4.2) | 95.20% (−1.8) |

Neither candidate works, and neither does anything else in the dumps. To produce those readings against
`DesignCapacity` the numerator would have to be 5498-5559 and 6030-6093 respectively; no key holds a value
in either range, and no ratio of any two keys lands on them. `NominalChargeCapacity` cannot rescue it —
across all nine dumps with a battery it sits a near-constant +2.4 to +2.8 points above
`AppleRawMaxCapacity`, so it only shifts a constant, while the error above flips sign.

The likeliest explanation is that macOS displays a smoothed or cached figure rather than a live gauge
reading. `BatteryRepository` keeps `AppleRawMaxCapacity / DesignCapacity`, which is what coconutBattery
reports. Two readings are far too few to fit anything against, which is why the request above matters.

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
