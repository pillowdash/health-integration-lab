# Lesson 27 — Filter Omnicell ZPM messages by item ID

## Scenario
In the Epic Bridges TST environment, AIP 334617 (incoming Omnicell dispense/load transactions) received ZPM^ZPM message 5678. Its item identifier `PTOWNOVERNITE` is in Kaitlin's requested exclusion list. The message also showed Epic error 8751 with invalid `PHA.LCB`, but filtering the item is a separate decision from resolving that reference error.

## Objective
Build a **pure Tcl 8.6** decision function that reads an external list of item identifiers and determines whether a ZPM message should be excluded. All example payloads are synthetic and contain no patient data.

Important fields: `MSH-9 = ZPM^ZPM`, `ZPM-1 = transaction type`, `ZPM-6 = item ID`. Split the `ZPM` segment on the HL7 `|` delimiter and retrieve Tcl list index `6` for ZPM-6.

## Scope choices
- `ALL` (default): exclude any ZPM transaction whose ZPM-6 exactly matches a listed ID.
- `LOAD_ONLY`: exclude only when **both** ZPM-1 is `L` and ZPM-6 matches.

The original email refers to unwanted *load* messages. The choice to exclude **all** transaction types requires business confirmation before any production use.

## Run it
From the root of your `health-integration-lab` project, after copying the `tcl` subfolders from this package:

```bash
tclsh tcl/tests/27_test_omnicell_zpm_item_filter.tcl
tclsh tcl/tps/27_omnicell_zpm_item_filter.tcl tcl/samples/27_zpm_excluded_load.hl7
tclsh tcl/tps/27_omnicell_zpm_item_filter.tcl tcl/samples/27_zpm_allowed_load.hl7
tclsh tcl/tps/27_omnicell_zpm_item_filter.tcl tcl/samples/27_zpm_excluded_load.hl7 LOAD_ONLY
```

Expected decisions: excluded load => `KILL`; allowed load => `CONTINUE`; malformed messages => `REVIEW`. For the unload case, `ALL` returns `KILL` while `LOAD_ONLY` returns `CONTINUE`.

## Implementation notes
- IDs are **strings**: `00000000` must retain its leading zeros.
- Matching is exact and case-sensitive: `PTOWNOVERNITE2` must not match `PTOWNOVERNITE`.
- Internal spaces matter: `PTS OWN HYCODAN` is different from `PTSOWNHYCODAN`.
- Use a hash/dictionary lookup for efficient membership tests.
- For malformed messages, this lab returns `REVIEW` instead of silently dropping them or treating them as clean. A real integration-engine route requires a defined exception/quarantine policy.
- Never deploy this standalone Tcl script as a Cloverleaf TPS without a proper engine-specific adapter for message handles, acknowledgements, monitoring, and audit logging.
- Suppression should be restricted to the appropriate **Omnicell → Epic TST route**, not a shared route serving other consumers.
- Never change the error severity merely to hide inbound unwanted items; that does not implement filtering.
- The blocklist was transcribed from screenshots as a training aid. Confirm every ID against Kaitlin's original Excel before implementation.

## Practice exercises
1. Change the default behavior from `ALL` to `LOAD_ONLY` in a wrapper and rerun tests.
2. Add a second excluded ZPM segment to one message and observe the decision.
3. Print a CSV audit record with timestamp, message control ID, ZPM-1, ZPM-6, and decision (no patient data).
4. Add a replay-safe dry-run mode that reports exclusions without suppressing any messages.
5. In the future, adapt the function to Cloverleaf's TPS message-handle API; test both routing suppression and correct ACK behavior.
