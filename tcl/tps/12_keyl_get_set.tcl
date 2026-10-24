# ============================================================
# TclX keyed-list demo for Cloverleaf / HL7
# ============================================================

package require Tclx

# A TclX keyed list is a key/value data structure like a Tcl associative array, but it is a first-class Tcl value and supports hierarchical/nested keys.
# A TclX keyed list is a key/value data structure more like a Tcl dict, which is also a first-class Tcl value and supports hierarchical/nested keys.

# ------------------------------------------------------------
# Create a keyed list containing Cloverleaf-style TPS args
# ------------------------------------------------------------

set tpsArgs {}

keylset tpsArgs \
    MODE run \
    MSGID mh_1001 \
    ARGS.INTERFACE OLIS_OUT \
    ARGS.ENVIRONMENT TEST


puts "=== TPS KEYED LIST ==="
puts $tpsArgs


# ------------------------------------------------------------
# Read values
# ------------------------------------------------------------

keylget tpsArgs MODE mode
keylget tpsArgs MSGID mh

puts ""
puts "MODE  = $mode"
puts "MSGID = $mh"


puts ""
puts "Interface:"
puts [keylget tpsArgs ARGS.INTERFACE]

puts "Environment:"
puts [keylget tpsArgs ARGS.ENVIRONMENT]


# ------------------------------------------------------------
# Build HL7-related metadata
# ------------------------------------------------------------

set hl7Info {}

keylset hl7Info \
    MSH.MESSAGE_CODE ORU \
    MSH.TRIGGER_EVENT R01 \
    MSH.CONTROL_ID MSG1001 \
    PID.MRN 123456 \
    PID.LAST_NAME SMITH \
    PID.FIRST_NAME JOHN \
    ROUTING.SOURCE EPIC \
    ROUTING.DESTINATION OLIS


puts ""
puts "=== HL7 INFO ==="

puts "Message = [keylget hl7Info MSH.MESSAGE_CODE]^[keylget hl7Info MSH.TRIGGER_EVENT]"
puts "MRN     = [keylget hl7Info PID.MRN]"
puts "Patient = [keylget hl7Info PID.LAST_NAME], [keylget hl7Info PID.FIRST_NAME]"
puts "Route   = [keylget hl7Info ROUTING.SOURCE] -> [keylget hl7Info ROUTING.DESTINATION]"


# ------------------------------------------------------------
# Update a value
# ------------------------------------------------------------

puts ""
puts "=== UPDATE ==="

keylset hl7Info ROUTING.DESTINATION OLIS_TEST

puts "New destination = [keylget hl7Info ROUTING.DESTINATION]"


# ------------------------------------------------------------
# Show keys
# ------------------------------------------------------------

puts ""
puts "=== TOP-LEVEL KEYS ==="

puts [keylkeys hl7Info]


puts ""
puts "=== KEYS UNDER PID ==="

puts [keylkeys hl7Info PID]


# ------------------------------------------------------------
# Delete a value
# ------------------------------------------------------------

puts ""
puts "=== DELETE ==="

keyldel hl7Info PID.FIRST_NAME

puts "After deleting PID.FIRST_NAME:"
puts $hl7Info

# TclX supports hierarchical keys.
set patient {}

keylset patient \
    MRN 123456 \
    NAME.LAST SMITH \
    NAME.FIRST JOHN \
    ADDRESS.CITY Burlington \
    ADDRESS.PROVINCE ON

puts ""
puts "hierarchical keys"
puts "MRN       = [keylget patient MRN]"
puts "Last name = [keylget patient NAME.LAST]"
puts "First     = [keylget patient NAME.FIRST]"
puts "City      = [keylget patient ADDRESS.CITY]"
