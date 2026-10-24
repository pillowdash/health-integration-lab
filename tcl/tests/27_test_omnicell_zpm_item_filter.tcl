# Execute from the project root:
#   tclsh tcl/tests/27_test_omnicell_zpm_item_filter.tcl
set thisDir [file dirname [file normalize [info script]]]
source [file join $thisDir .. tps 27_omnicell_zpm_item_filter.tcl]
set blocked [::omnicellZpm::readBlocklist [file join $thisDir .. data omnicell_zpm_blocklist.txt]]

proc makeZpm {transaction id} {
    # \& is the literal HL7 MSH escape character; CR separates HL7 segments.
    return "MSH|^~\\&|OMNICELL|JB|EPIC|JB|20261014115208||ZPM^ZPM|TEST27|T|2.4\rZPM|$transaction||JB4NORTH|||$id|TRAINING ITEM\r"
}
proc expect {name expected hl7 blocked {mode ALL}} {
    set result [::omnicellZpm::filter $hl7 $blocked $mode]
    set actual [dict get $result action]
    if {$actual ne $expected} {
        error "FAIL: $name — expected $expected, got $actual ([dict get $result reason])"
    }
    puts "PASS: $name => $actual"
}

if {[dict size $blocked] != 23} {
    error "Expected 23 item IDs in lab blocklist, got [dict size $blocked]"
}
expect "excluded load" KILL [makeZpm L PTOWNOVERNITE] $blocked
expect "excluded unload, ALL mode" KILL [makeZpm U PTOWNOVERNITE] $blocked
expect "excluded unload, LOAD_ONLY mode" CONTINUE [makeZpm U PTOWNOVERNITE] $blocked LOAD_ONLY
expect "excluded load, LOAD_ONLY mode" KILL [makeZpm L PTOWNOVERNITE] $blocked LOAD_ONLY
expect "allowed item" CONTINUE [makeZpm L NORMAL123] $blocked
expect "leading-zero ID is a string" KILL [makeZpm L 00000000] $blocked
expect "internal spaces preserved" KILL [makeZpm L {PTS OWN HYCODAN}] $blocked
expect "partial match must not block" CONTINUE [makeZpm L PTOWNOVERNITE2] $blocked
expect "missing item ID requires review" REVIEW [makeZpm L {}] $blocked
expect "missing field requires review" REVIEW "MSH|^~\\&|OMNICELL|JB|EPIC|JB|20261014115208||ZPM^ZPM|TEST27|T|2.4\rZPM|L||JB4NORTH\r" $blocked
expect "non-ZPM message continues" CONTINUE {MSH|^~\&|EPIC|JB|LAB|JB|20261014115208||ADT^A08|TEST27|T|2.5
PID|1||1234^^^JB^MR} $blocked
expect "ZPM header without segment requires review" REVIEW {MSH|^~\&|OMNICELL|JB|EPIC|JB|20261014115208||ZPM^ZPM|TEST27|T|2.4} $blocked
puts "ALL 12 TESTS PASSED"
