proc filter_message {msg metadata} {

    set interface [dict get $metadata interface]
    set direction [dict get $metadata direction]

    puts "=== Message Context ==="
    puts "Interface   : $interface"
    puts "Source      : [dict get $metadata source]"
    puts "Destination : [dict get $metadata destination]"
    puts "Direction   : $direction"
    puts "Environment : [dict get $metadata environment]"
    puts ""

    if {$interface ne "334720"} {
        return "KILL"
    }

    if {$direction ne "OUTBOUND"} {
        return "KILL"
    }    

    set segments [split $msg "\r"]

    foreach segment $segments {

        set fields [split $segment "|"]
        set segmentName [lindex $fields 0]

        if {$segmentName eq "MSH"} {

            set msh9 [lindex $fields 8]
            set msh9Components [split $msh9 "^"]

            set messageType [lindex $msh9Components 0]
            set triggerEvent [lindex $msh9Components 1]

            puts "MSH-9         = $msh9"
            puts "Message Type  = $messageType"
            puts "Trigger Event = $triggerEvent"

            if {$messageType eq "ADT" &&
                ($triggerEvent eq "A08" || $triggerEvent eq "A31")} {

                return "CONTINUE"
            } else {
                return "KILL"
            }
        }
    }

    return "ERROR"
}

set msg "MSH|^~\\&|EPIC|TSH|OLIS|OLIS|202610010800||ADT^A08|12345|P|2.3\rPID|1||123456^^^TSH^MR||SMITH^JOHN||19800101|M"

set metadata [dict create \
    interface 334720 \
    source EPIC \
    destination OLIS \
    direction OUTBOUND \
    environment TEST]


set result [filter_message $msg $metadata]

puts ""
puts "Disposition = $result"

set testCases [list \
    [dict create \
        msg "MSH|^~\\&|EPIC|TSH|DOWNSTREAM|SYSTEM|202609302100||ADT^A08|12345|P|2.3\rPID|1||123456^^^TSH^MR||SMITH^JOHN||19800101|M" \
        metadata [dict create \
            interface 334720 \
            source EPIC \
            destination OLIS \
            direction OUTBOUND \
            environment TEST]] \
    [dict create \
        msg "MSH|^~\\&|EPIC|TSH|DOWNSTREAM|SYSTEM|202609302100||ADT^A31|12345|P|2.3\rPID|1||123456^^^TSH^MR||SMITH^JOHN||19800101|M" \
        metadata [dict create \
            interface 334720 \
            source EPIC \
            destination OLIS \
            direction OUTBOUND \
            environment TEST]] \
    [dict create \
        msg "MSH|^~\\&|EPIC|TSH|DOWNSTREAM|SYSTEM|202609302100||ADT^A08|12345|P|2.3\rPID|1||123456^^^TSH^MR||SMITH^JOHN||19800101|M" \
        metadata [dict create \
            interface 334720 \
            source EPIC \
            destination OLIS \
            direction INBOUND \
            environment TEST]] \
    [dict create \
        msg "MSH|^~\\&|EPIC|TSH|DOWNSTREAM|SYSTEM|202609302100||ADT^A08|12345|P|2.3\rPID|1||123456^^^TSH^MR||SMITH^JOHN||19800101|M" \
        metadata [dict create \
            interface 999999 \
            source EPIC \
            destination OLIS \
            direction OUTBOUND \
            environment TEST]] \
]



foreach testCase $testCases {

    puts "-----------------------------"

    set metadata [dict get $testCase metadata]
    set msg [dict get $testCase msg]


    set result [filter_message $msg $metadata]

    puts ""


    puts "Disposition = $result"
}
