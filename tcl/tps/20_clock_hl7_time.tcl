# ============================================================
# LESSON 20
# Tcl clock + HL7 timestamps
#
# Main commands:
#
#   clock seconds
#   clock milliseconds
#   clock format
#   clock scan
#   clock add
#
# ============================================================

lappend auto_path [file normalize "tcl/lib"]

package require hl7utils

puts "============================================================"
puts "1. CURRENT TIME"
puts "============================================================"


# Unix epoch seconds:
#
# Number of seconds since:
#
#   1970-01-01 00:00:00 UTC
#
set now [clock seconds]

puts "clock seconds = $now"


# Human-readable local time
puts "Local time = [clock format $now]"


# Explicit format
puts "Formatted = [clock format $now \
    -format "%Y-%m-%d %H:%M:%S"]"

puts ""
puts "============================================================"
puts "2. HL7 TIMESTAMP"
puts "============================================================"


set hl7Timestamp \
    [clock format [clock seconds] \
        -format "%Y%m%d%H%M%S"]


puts "HL7 timestamp = $hl7Timestamp"


puts ""
puts "============================================================"
puts "3. MILLISECOND TIMING"
puts "============================================================"


set start [clock milliseconds]

# Simulate some work
after 250

set finish [clock milliseconds]


set elapsed \
    [expr {$finish - $start}]


puts "Start   = $start"
puts "Finish  = $finish"
puts "Elapsed = $elapsed ms"


puts ""
puts "============================================================"
puts "4. CLOCK SCAN"
puts "============================================================"


set textDate "2026-10-07 13:30:00"

set epoch \
    [clock scan $textDate \
        -format "%Y-%m-%d %H:%M:%S"]


puts "Input = $textDate"
puts "Epoch = $epoch"

puts "Back again = [clock format $epoch \
    -format "%Y-%m-%d %H:%M:%S"]"


puts ""
puts "============================================================"
puts "5. CLOCK ADD"
puts "============================================================"


set now [clock seconds]


set oneHourLater \
    [clock add $now 1 hour]


set oneDayLater \
    [clock add $now 1 day]


puts "Now:"
puts [clock format $now]


puts ""
puts "One hour later:"
puts [clock format $oneHourLater]


puts ""
puts "One day later:"
puts [clock format $oneDayLater]


puts ""
puts "============================================================"
puts "6. HL7 OBSERVATION AGE"
puts "============================================================"


set observationTimestamp "20261007120000"


set observationEpoch \
    [clock scan $observationTimestamp \
        -format "%Y%m%d%H%M%S"]


set now \
    [clock seconds]


set ageSeconds \
    [expr {$now - $observationEpoch}]


set ageMinutes \
    [expr {$ageSeconds / 60.0}]


puts "OBX-14 = $observationTimestamp"

puts [format \
    "Observation age = %.1f minutes" \
    $ageMinutes]


puts ""
puts "============================================================"
puts "7. READ MSH-7 USING hl7_utils"
puts "============================================================"


set msg [join [list \
    "MSH|^~\\&|EPIC|TSH|LAB|TSH|20261007131530||ORU^R01|MSG20001|P|2.5" \
    "PID|1||123456^^^TSH^MR||SMITH^JOHN" \
    "OBX|1|NM|K^Potassium||5.8|mmol/L|3.5-5.1|H|||F|||20261007120000" \
] "\r"]


set msh7 \
    [hl7::get $msg "MSH-7"]


puts "MSH-7 = $msh7"


set messageEpoch \
    [clock scan $msh7 \
        -format "%Y%m%d%H%M%S"]


puts "Readable = [clock format $messageEpoch \
    -format "%Y-%m-%d %H:%M:%S"]"


puts ""
puts "============================================================"
puts "8. PERFORMANCE TEST"
puts "============================================================"


set iterations 10000


set start \
    [clock milliseconds]


for {set i 0} {$i < $iterations} {incr i} {

    set value \
        [hl7::get $msg "OBX-5"]
}


set elapsed \
    [expr {[clock milliseconds] - $start}]


puts "Iterations = $iterations"
puts "Elapsed    = $elapsed ms"


if {$elapsed > 0} {

    puts [format \
        "Average = %.4f ms/call" \
        [expr {$elapsed / double($iterations)}]]
}
