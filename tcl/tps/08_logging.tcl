proc log_message {level message metadata msg} {

    set timestamp [clock format [clock seconds] \
        -format "%Y-%m-%d %H:%M:%S"]

    set interface [dict get $metadata interface]
    set controlId [get_message_control_id $msg]
    puts "$timestamp $level interface=$interface controlId=$controlId $message"
}

proc get_message_control_id {msg} {

    set segments [split $msg "\r"]

    foreach segment $segments {

        set fields [split $segment "|"]

        if {[lindex $fields 0] eq "MSH"} {

            # MSH-10 -> Tcl index 9
            return [lindex $fields 9]
        }
    }

    return "UNKNOWN"
}

#log_message INFO "Starting interface processing"
#log_message WARNING "XTN country mismatch"
#log_message ERROR "Transformation failed"

set metadata [dict create \
    interface 334720 \
    source EPIC \
    destination OLIS \
    direction OUTBOUND \
    environment TEST]

set msg "MSH|^~\\&|EPIC|TSH|OLIS|OLIS|202610010900||ADT^A08|12345|P|2.3\rPID|1||123456^^^OLDBOSP^MR||SMITH^JOHN||19800101|M"
log_message INFO "Starting message processing" $metadata $msg
