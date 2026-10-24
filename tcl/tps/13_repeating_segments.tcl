lappend auto_path [file normalize "tcl/lib"]

package require hl7utils


set msg "MSH|^~\\&|LABSYS|TSH|EPIC|TSH|202610031600||ORU^R01^ORU_R01|ORU000701|P|2.5\rPID|1||123456^^^TSH^MR||SMITH^JOHN||19800101|M|||123 MAIN ST^^MARKHAM^ON^L3R1A1^CAN||(905)555-1234^PRN^PH^^1^905^5551234~john.smith@example.com^NET^Internet\rOBR|1|ORD1001|LAB1001|CBC^Complete Blood Count|||202610031500\rOBX|1|NM|WBC^White Blood Cells||7.4|10^9/L|4.0-11.0|N|||F\rOBX|2|NM|HGB^Hemoglobin||145|g/L|135-175|N|||F\rOBX|3|NM|PLT^Platelets||250|10^9/L|150-400|N|||F\rOBR|2|ORD1002|LAB1002|BMP^Basic Metabolic Panel|||202610031505\rOBX|1|NM|NA^Sodium||140|mmol/L|135-145|N|||F\rOBX|2|NM|K^Potassium||5.8|mmol/L|3.5-5.1|H|||F"


puts "Message Type = [hl7::get $msg MSH-9]"
puts "Control ID   = [hl7::get $msg MSH-10]"

puts ""

set obxSegments [hl7::get_segments $msg OBX]

puts "OBX count = [llength $obxSegments]"

puts ""
puts "=== Every OBX ==="

set occurrence 1

foreach obx $obxSegments {

    puts "OBX occurrence $occurrence:"
    puts "  $obx"

    incr occurrence
}


puts ""
puts "=== All OBX-5 values ==="

set values [hl7::get_all $msg "OBX-5"]

set occurrence 1

foreach value $values {

    puts "OBX occurrence $occurrence value = $value"

    incr occurrence
}


puts ""
puts "=== All OBX-3 observation identifiers ==="

set observations [hl7::get_all $msg "OBX-3"]

foreach observation $observations {
    puts $observation
}


puts ""
puts "=== All OBX-8 abnormal flags ==="

set flags [hl7::get_all $msg "OBX-8"]

foreach flag $flags {
    puts $flag
}


set observations [hl7::get_all $msg "OBX-3"]
set values       [hl7::get_all $msg "OBX-5"]
set flags        [hl7::get_all $msg "OBX-8"]

for {set i 0} {$i < [llength $values]} {incr i} {

    set observation [lindex $observations $i]
    set value       [lindex $values $i]
    set flag        [lindex $flags $i]

    if {$flag ne "" && $flag ne "N"} {

        puts ""
        puts "*** ABNORMAL RESULT ***"
        puts "Observation = $observation"
        puts "Value       = $value"
        puts "Flag        = $flag"
    }
}


set contacts [hl7::get_repetitions $msg "PID-13"]

puts ""
puts "PID-13 repetitions = [llength $contacts]"

set repetitionNumber 1

foreach contact $contacts {

    puts "Repetition $repetitionNumber = $contact"

    incr repetitionNumber
}
