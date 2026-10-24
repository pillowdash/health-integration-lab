namespace eval logger {

    proc log {level message metadata msg} {

        set timestamp [clock format [clock seconds] \
            -format "%Y-%m-%d %H:%M:%S"]

        set interface [dict get $metadata interface]

        set controlId [hl7::get_message_control_id $msg]

        puts "$timestamp $level interface=$interface controlId=$controlId $message"
    }
}

package provide logger 1.0
