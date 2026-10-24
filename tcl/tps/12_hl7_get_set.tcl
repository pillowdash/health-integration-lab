lappend auto_path [file normalize "tcl/lib"]

package require hl7utils

set msg "MSH|^~\\&|LABSYS|TSH|EPIC|TSH|202610031100||ORU^R01^ORU_R01|ORU000601|P|2.5\rPID|1||123456^^^TSH^MR||SMITH^JOHN||19800101|M\rOBR|1|ORD1001|LAB1001|CBC^Complete Blood Count|||202610031000\rOBX|1|NM|WBC^White Blood Cells||7.4|10^9/L|4.0-11.0|N|||F"

puts "Message Type = [hl7::get $msg MSH-9]"
puts "Message Code = [hl7::get $msg MSH-9.1]"
puts "Trigger      = [hl7::get $msg MSH-9.2]"

puts ""

puts "MRN          = [hl7::get $msg PID-3.1]"
puts "Authority    = [hl7::get $msg PID-3.4]"
puts "Last Name    = [hl7::get $msg PID-5.1]"
puts "First Name   = [hl7::get $msg PID-5.2]"

puts ""

puts "OBX Value    = [hl7::get $msg OBX-5]"
puts "OBX Units    = [hl7::get $msg OBX-6]"
puts "OBX Flag     = [hl7::get $msg OBX-8]"


puts ""
puts "=== ORIGINAL ==="
puts [string map {"\r" "\n"} $msg]

set msg2 [hl7::set_field $msg "PID-3.4" "TSH20001"]

puts ""
puts "=== TRANSFORMED ==="
puts [string map {"\r" "\n"} $msg2]
