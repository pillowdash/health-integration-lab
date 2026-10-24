# ============================================================
# LESSON 14
# TclHL7 Addressing Library
#
# Goal:
#
#   raw HL7
#      ↓
#   hl7 parse
#      ↓
#   query / get / set
#      ↓
#   hl7 data
#      ↓
#   raw HL7 again
#
# This follows Lesson 13:
#   repeating segments / fields / repetitions
# ============================================================


# ------------------------------------------------------------
# 1. Locate and load TclHL7
# ------------------------------------------------------------

set scriptDir [file dirname [file normalize [info script]]]

puts $scriptDir

# We are currently:
#
#   tcl/tps/14_tclhl7_addressing.tcl
#
# TclHL7 is:
#
#   tcl/vendor/tclhl7/build/hl7.tcl
#
set tclRoot [file normalize [file join $scriptDir ..]]

set tclhl7File \
    [file join $tclRoot vendor tclhl7 build hl7.tcl]


puts "Loading:"
puts $tclhl7File

if {![file exists $tclhl7File]} {
    error "TclHL7 library not found: $tclhl7File"
}

source $tclhl7File


puts ""
puts "HL7 command available?"

puts [info commands hl7]


# ============================================================
# 2. Build an ORU^R01 test message
#
# Notice:
#
#   PID-3 repeats
#
#   OBR #1
#       OBX #1
#       OBX #2
#       OBX #3
#
#   OBR #2
#       OBX #1
#       OBX #2
#
# This connects directly to Lessons 11 and 13.
# ============================================================

set msgdata [join [list \
    "MSH|^~\\&|EPIC|TSH|OLIS|OLIS|202610061500||ORU^R01|MSG1001|P|2.5" \
    "PID|1||123456^^^TSH^MR~9999999999^^^ON^JHN||SMITH^JOHN" \
    "OBR|1|ORD1001|LAB1001|CBC^Complete Blood Count" \
    "OBX|1|NM|WBC^White Blood Cells||7.4|10*9/L|4.0-11.0|N|||F" \
    "OBX|2|NM|HGB^Hemoglobin||145|g/L|120-160|N|||F" \
    "OBX|3|NM|PLT^Platelets||250|10*9/L|150-400|N|||F" \
    "OBR|2|ORD1002|LAB1002|BMP^Basic Metabolic Panel" \
    "OBX|1|NM|NA^Sodium||140|mmol/L|135-145|N|||F" \
    "OBX|2|NM|K^Potassium||5.8|mmol/L|3.5-5.1|H|||F" \
] "\r"]


puts ""
puts "============================================================"
puts "ORIGINAL HL7"
puts "============================================================"

puts [string map {"\r" "\n"} $msgdata]


# ============================================================
# 3. Parse the message
# ============================================================

puts ""
puts "============================================================"
puts "PARSE MESSAGE"
puts "============================================================"

set msg [hl7 parse $msgdata]

puts "Message parsed successfully"


# ============================================================
# 4. Read MSH-9
#
# Address structure:
#
# MSH.9.0.0.0
# │   │ │ │ │
# │   │ │ │ └── subcomponent 0
# │   │ │ └──── component 0
# │   │ └────── repetition 0
# │   └──────── field 9
# └──────────── segment MSH
#
# MSH-9 = ORU^R01
#
# component 0 = ORU
# component 1 = R01
# ============================================================

puts ""
puts "============================================================"
puts "MSH-9"
puts "============================================================"

set messageCode \
    [lindex [hl7 get values $msg MSH.9.0.0.0] 0]

set triggerEvent \
    [lindex [hl7 get values $msg MSH.9.0.1.0] 0]

puts "Message code  = $messageCode"
puts "Trigger event = $triggerEvent"

puts "Combined      = ${messageCode}^${triggerEvent}"

# ============================================================
# 5. PID-3 repetitions
# ============================================================

puts ""
puts "============================================================"
puts "PID-3 REPETITIONS"
puts "============================================================"


set identifiers \
    [hl7 get values $msg PID.3.*.0.0]


puts "PID-3 identifier values:"
puts $identifiers


puts ""
puts "Loop through identifiers:"

foreach id $identifiers {
    puts "  Identifier = $id"
}


puts ""
puts "============================================================"
puts "PID-3 DETAILS"
puts "============================================================"

set assigningAuthorities \
    [hl7 get values $msg PID.3.*.3.0]

set identifierTypes \
    [hl7 get values $msg PID.3.*.4.0]


puts "Identifiers:"
puts $identifiers

puts "Assigning authorities:"
puts $assigningAuthorities

puts "Identifier types:"
puts $identifierTypes

puts ""
puts "PID-3 detail:"


set ids \
    [hl7 get values $msg PID.3.*.0.0]

set authorities \
    [hl7 get values $msg PID.3.*.3.0]

set types \
    [hl7 get values $msg PID.3.*.4.0]


for {set i 0} {$i < [llength $ids]} {incr i} {

    puts [format \
        "rep=%d  ID=%-12s authority=%-4s type=%s" \
        $i \
        [lindex $ids $i] \
        [lindex $authorities $i] \
        [lindex $types $i]]
}


# ============================================================
# 6. Get ALL OBX-5 values
# ============================================================

puts ""
puts "============================================================"
puts "ALL OBX-5 VALUES"
puts "============================================================"

set results \
    [hl7 get values $msg OBX.5.0.0.0]


puts "All values:"
puts $results


foreach value $results {
    puts "OBX-5 = $value"
}


puts ""
puts "============================================================"
puts "GET VALUE + ADDRESS"
puts "============================================================"


set matches \
    [hl7 get $msg OBX.5.0.0.0]


foreach match $matches {

    set value   [lindex $match 0]
    set address [lindex $match 1]

    puts "Address=$address  Value=$value"
}


puts ""
puts "============================================================"
puts "SET MSH-6"
puts "============================================================"


set msg \
    [hl7 set $msg MSH.6.0.0.0 "OLIS"]


puts "New MSH-6:"
puts [hl7 get values $msg MSH.6.0.0.0]

puts ""
puts "============================================================"
puts "SET ALL OBX-11"
puts "============================================================"


set msg \
    [hl7 set $msg OBX.11.0.0.0 "F"]


set statuses \
    [hl7 get values $msg OBX.11.0.0.0]

puts "OBX statuses:"
puts $statuses

# ============================================================
# 7. Convert parsed representation back to raw HL7
# ============================================================

puts ""
puts "============================================================"
puts "FINAL HL7"
puts "============================================================"


set newMsgData [hl7 data $msg]


puts [string map {"\r" "\n"} $newMsgData]
