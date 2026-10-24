source tcl/lib/hl7_utils.tcl
source tcl/lib/logging.tcl

set msg "MSH|^~\\&|EPIC|TSH|GECENTRICITY|TSH|202610011900||ADT^A08|334364.483|T|2.4\rPID|1||2101883^^^TSH^MR||SMITH^JOHN"

set controlId [hl7::get_message_control_id $msg]
set messageType [hl7::get_message_type $msg]

puts "Control ID   = $controlId"
puts "Message Type = $messageType"

set metadata [dict create \
    interface 334364 \
    source EPIC \
    destination CPN \
    direction OUTBOUND \
    environment TEST]


logger::log INFO "Message received" $metadata $msg
