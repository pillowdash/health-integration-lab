# ------------------------------------------------------------
# CASE 2
#
# We have TWO HL7 message variables:
#
#     inboundMsg
#     outboundMsg
#
# Another variable contains the NAME of the message variable
# we want to modify.
#
# This is where:
#
#     modify_message $selectedMessage
#
# becomes useful.
# ------------------------------------------------------------

# scenario - Another variable tells me the variable name
#
set inboundMsg  "MSH|^~\\&|EPIC|TSH|ENGINE|TSH|202610041210||SIU^S12|IN001|P|2.5\rPID|1||111111^^^TSH^MR||SMITH^JOHN"

set outboundMsg "MSH|^~\\&|ENGINE|TSH|SCHEDSYS|TSH|202610041210||SIU^S12|OUT001|P|2.5\rPID|1||111111^^^TSH^MR||SMITH^JOHN"


proc add_processing_segment {variableName} {

    # Suppose variableName contains:
    #
    #     outboundMsg
    #
    # Then this becomes conceptually:
    #
    #     upvar 1 outboundMsg msg
    #
    # msg becomes an alias for the caller's outboundMsg.
    #
    upvar 1 $variableName msg

    append msg "\rZXX|PROCESSED"
}


# ------------------------------------------------------------
# Runtime decision:
#
# Imagine Cloverleaf decides that the OUTBOUND message
# should be modified.
#
# selectedMessage does NOT contain an HL7 message.
#
# It contains the STRING:
#
#     outboundMsg
#
# which is the NAME of another variable.
# ------------------------------------------------------------

set direction "OUTBOUND"

if {$direction eq "OUTBOUND"} {

    set selectedMessage "outboundMsg"

} else {

    set selectedMessage "inboundMsg"
}


puts "Direction       = $direction"
puts "selectedMessage = $selectedMessage"

puts ""
puts "=== BEFORE ==="

puts "Inbound:"
puts [string map {"\r" "\n"} $inboundMsg]

puts ""

puts "Outbound:"
puts [string map {"\r" "\n"} $outboundMsg]


# ------------------------------------------------------------
# THIS IS THE IMPORTANT LINE.
#
# selectedMessage contains:
#
#     outboundMsg
#
# Therefore:
#
#     $selectedMessage
#
# evaluates to:
#
#     outboundMsg
#
# So Tcl effectively executes:
#
#     add_processing_segment outboundMsg
# ------------------------------------------------------------

add_processing_segment $selectedMessage


puts ""
puts "=== AFTER ==="

puts "Inbound:"
puts [string map {"\r" "\n"} $inboundMsg]

puts ""

puts "Outbound:"
puts [string map {"\r" "\n"} $outboundMsg]
