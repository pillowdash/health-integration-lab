lappend auto_path [file normalize "tcl/lib"]

package require hl7utils
package require logger
package require xtn

puts $auto_path

set msg "MSH|^~\\&|EPIC|TSH|SCHEDSYS|TSH|202610021700||SIU^S12|SIU000123|P|2.5\rSCH|APT12345|||||FOLLOWUP^Follow-up Visit|||30|min|||||||||BOOKED\rPID|1||123456^^^TSH^MR||SMITH^JOHN||19800101|M\rPV1|1|O|CLINIC1^^^TSH||||1234^JONES^SARAH\rRGS|1\rAIS|1||CARDIO^Cardiology Follow-up\rAIP|1||1234^JONES^SARAH"

set typeInfo [hl7::get_message_type_components $msg]

puts "Message Code  = [dict get $typeInfo messageCode]"
puts "Trigger Event = [dict get $typeInfo triggerEvent]"


set sch [hl7::get_segment $msg "SCH"]
set pid [hl7::get_segment $msg "PID"]
set ais [hl7::get_segment $msg "AIS"]

puts "SCH = $sch"
puts "PID = $pid"
puts "AIS = $ais"


proc process_siu {msg} {

    set sch [hl7::get_segment $msg "SCH"]

    if {$sch eq ""} {
        return [dict create \
            disposition ERROR \
            error "SIU message does not contain SCH"]
    }

    set fields [split $sch "|"]

    set appointmentId [lindex $fields 1]

    puts "Appointment ID = $appointmentId"

    return [dict create \
        disposition CONTINUE \
        appointmentId $appointmentId]
}

set typeInfo [hl7::get_message_type_components $msg]

set messageCode [dict get $typeInfo messageCode]
set triggerEvent [dict get $typeInfo triggerEvent]

if {$messageCode eq "SIU"} {

    set result [process_siu $msg]

    puts "Disposition = [dict get $result disposition]"
}
