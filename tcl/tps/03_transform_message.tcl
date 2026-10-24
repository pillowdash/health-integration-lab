proc log_message {level message metadata msg} {

    set timestamp [clock format [clock seconds] \
        -format "%Y-%m-%d %H:%M:%S"]

    set interface [dict get $metadata interface]
    set controlId [get_message_control_id $msg]
    #puts "$timestamp $level interface=$interface controlId=$controlId $message"

    set line "$timestamp $level interface=$interface controlId=$controlId $message"

    puts $line

    set fh [open "tcl/logs/interface.log" a]
    puts $fh $line
    close $fh    
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



proc transform_message {msg metadata} {

    set interface [dict get $metadata interface]

    set segments [split $msg "\r"]
    set newSegments {}

    foreach segment $segments {

        set fields [split $segment "|"]
        set segmentName [lindex $fields 0]

        if {$segmentName eq "PID"} {

            set pid3 [lindex $fields 3]

            puts "Original PID-3 = $pid3"

            set pid3Components [split $pid3 "^"]

            set mrn       [lindex $pid3Components 0]
            set authority [lindex $pid3Components 3]
            set idType    [lindex $pid3Components 4]

            puts "MRN       = $mrn"
            puts "Authority = $authority"
            puts "ID Type   = $idType"

            if {$interface eq "334720"} {
                set authority "TSH"
            }

            set newPid3 "$mrn^^^$authority^$idType"

            puts "New PID-3 = $newPid3"

            lset fields 3 $newPid3

            set segment [join $fields "|"]
        }

        lappend newSegments $segment
    }

    set newMsg [join $newSegments "\r"]

    # Make the validator deliberately fail: comment out the line below
    #error "Simulated transformation failure"

    return $newMsg
}

proc safe_transform_message {msg metadata} {

    log_message INFO "Starting transformation" $metadata $msg

    if {[catch {

        # Remove $ sign - try it out for catch to work
        #set transformed [transform_message $msg metadata]

        set transformed [transform_message $msg $metadata]

    } err]} {

       log_message ERROR \
          "Transformation failed: $err" \
          $metadata \
          $msg

        #puts "ERROR while transforming message: $err"

        return [dict create \
            disposition ERROR \
            message $msg \
            error $err]
    }

    log_message INFO \
        "Transformation completed successfully" \
        $metadata \
        $msg
    return [dict create \
        disposition CONTINUE \
        message $transformed \
        error ""]
}

set msg "MSH|^~\\&|EPIC|TSH|OLIS|OLIS|202610010900||ADT^A08|12345|P|2.3\rPID|1||123456^^^OLDBOSP^MR||SMITH^JOHN||19800101|M"
set metadata [dict create \
    interface 334720 \
    source EPIC \
    destination OLIS \
    direction OUTBOUND \
    environment TEST]

#set transformedMsg [transform_message $msg $metadata]
set result [safe_transform_message $msg $metadata]

puts ""
puts "=== Original Message ==="
puts [string map {"\r" "\n"} $msg]

puts ""
puts "=== Processing Result ==="
#puts [string map {"\r" "\n"} $transformedMsg]
if {[dict get $result disposition] eq "CONTINUE"} {
	puts "Disposition = CONTINUE"
        puts ""
	puts "=== Transformed Message ==="
	puts [string map {"\r" "\n"} [dict get $result message]]
} elseif {[dict get $result disposition] eq "ERROR"} {
	puts "Disposition = ERROR"
	puts "Error: [dict get $result error]"
}
#set result [safe_transform_message $msg $metadata]

#puts ""
#puts "Disposition = [dict get $result disposition]"	
