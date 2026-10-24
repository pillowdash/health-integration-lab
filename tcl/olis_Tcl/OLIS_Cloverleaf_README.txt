OLIS TSH Cloverleaf Transformation Package
===========================================

Files
-----
1. olis_tsh_transform.tcl
   Core HL7 transformation library. Can be unit-tested under plain tclsh.

2. tps_olis_tsh_out.tcl
   Cloverleaf TPS wrapper using MODE / MSGID / msgget / msgset and returning
   CONTINUE or KILL dispositions.

3. olis_db_adapter_template.tcl
   Adapter contract for the SQL Server OLIS_Mapping stored procedure / lookup.

4. test_olis_rules.tcl
   Local unit tests for selected rules.

5. test_olis_tsh_transform.tcl
   End-to-end local example with a mock DB lookup.

Transformation coverage from the workbook ORU Change list
----------------------------------------------------------
- Remove SPM
- MSH-4 -> SampleConformanceID1
- PID-3 JHN / MR selection and formatting
- PID-5.7 -> U
- PID-11 country repetition filtering
- PID-13 / PID-14 XTN cleanup, 10-digit split, trailing serial removal
- ZPD creation / ZPD-2=Y when PID-3 has no JHN
- PV1-7 XCN normalization
- ORC-4.3 -> HL79901
- ORC-12 blank
- ORC-21 hardcode TSH organization
- ORC-24.7 -> H
- OBR-2 / OBR-3 assigning authority / ISO
- OBR-4 mapping / reduction to code^description^HL79901
- OBR-15 mapping and source-text carry-forward
- OBR-16 XCN normalization
- OBR-17 phone components
- OBR-24 blank
- OBR-28 XCN normalization
- OBR-29 OID appending
- OBR-30=PORT for POCT
- ZBR after each OBR, including source-dependent 37/JBS rules and sort key
- OBX-3 mapping / reduction to code^description^HL79902
- OBX-5 ED TEXT/Base64 changes
- OBX-5 CWE/CE transformation
- Empty OBX-5 behavior based on OBR-25 C/F
- OBX-4 <- OBX-1
- ZBX after each OBX; ZBX-1 <- MSH-7; ZBX-2 padded OBX-1
- NTE grouping with \.br\ and ZNT creation
- BLG-3=MOHLTC, default placement at end of message

Important items to confirm before production
--------------------------------------------
1. Workbook has two rows labelled PV1-7: one 'Attending physician' and one
   'Admitting physician'. Code transforms PV1-7 once. If admitting physician
   should actually be PV1-17, set:
       set ::olis::ALSO_TRANSFORM_PV1_17 1
   only after confirmation.

2. BLG placement conflicts in workbook:
   - one row says BLG before ORC / every order
   - numbered change says BLG at end of message
   Default is end-of-message. To use the older placement:
       set ::olis::BLG_MODE "before_each_orc"

3. Microbiology OBR-2/OBR-3 wording is ambiguous. Current code uses the common
   uniqueness interpretation: append "-<OBR-1>" to OBR-2.1 and OBR-3.1 when
   OBR-24=Microbiology and OBR-1>1. Confirm with a known expected example.

4. OBX-5 CWE wording says both 'copy OBX-5.5 to OBX-5.2' and 'hardcode
   (organism) to OBX-5.2'. Current code uses OBX-5.5 when present and falls
   back to '(organism)' only when OBX-5.5 is empty. Confirm expected output.

5. DB sheet shows dbo.RetrieveValue, but the visible SQL excerpt does not show
   @incomingValue in the WHERE condition. Verify the deployed stored procedure
   does filter on incoming value and returns the correct row.

6. Direct database access from a TPS should use your site's approved method and
   preferably a persistent/managed connection. Do not open/close a remote DB
   connection for each message if throughput is significant.

Installation outline
--------------------
- Put olis_tsh_transform.tcl and tps_olis_tsh_out.tcl in the site's Tcl area.
- Implement/source olis_db_lookup using your approved Cloverleaf DB/ODBC method.
- Edit ::OLIS_CORE_FILE in tps_olis_tsh_out.tcl or source core library earlier.
- Configure tps_olis_tsh_out in the appropriate outbound TPS location.
- Test with saved messages and compare field-by-field against expected OLIS
  outputs before promotion.

Local tests
-----------
    tclsh test_olis_rules.tcl
    tclsh test_olis_tsh_transform.tcl

The unit test currently reports ALL TESTS PASSED for the implemented isolated
rules.
