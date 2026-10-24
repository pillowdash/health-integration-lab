proc filter_message {msg} {

    set segments [split $msg "\r"]

    foreach segment $segments {

        set fields [split $segment "|"]

        set segmentName [lindex $fields 0]

        puts "Found segment: $segmentName"

        if {$segmentName eq "MSH"} {

	    # The field separator itself is MSH-1
	    # MSH-9 → index 8
            set msh9 [lindex $fields 8]

            puts "MSH-9 = $msh9"


	    set msh9Components [split $msh9 "^"]

	    set messageType [lindex $msh9Components 0]
	    set triggerEvent [lindex $msh9Components 1]

	    puts "Message Type  = $messageType"
	    puts "Trigger Event = $triggerEvent"

            if {$messageType eq "ADT" && ($triggerEvent eq "A08" || $triggerEvent eq "A31")} {
                return "CONTINUE"
            } else {
                return "KILL"
            }
        }
    }

    return "ERROR"
}


#set msg "MSH|^~\\&|EPIC|TSH|DOWNSTREAM|SYSTEM|202609302100||ADT^A08|12345|P|2.3\rPID|1||123456^^^TSH^MR||SMITH^JOHN||19800101|M"
#set msg "MSH|^~\\&|EPIC|TSH|DOWNSTREAM|SYSTEM|202609302100||ADT^A31|12345|P|2.3\rPID|1||123456^^^TSH^MR||SMITH^JOHN||19800101|M"
#set msg "MSH|^~\\&|EPIC|TSH|DOWNSTREAM|SYSTEM|202609302100||ADT^A03|12345|P|2.3\rPID|1||123456^^^TSH^MR||SMITH^JOHN||19800101|M"
#set msg "MSH|^~\\&|EPIC|TSH|DOWNSTREAM|SYSTEM|202609302100||ORU^R01|12345|P|2.3\rPID|1||123456^^^TSH^MR||SMITH^JOHN||19800101|M"

#set result [filter_message $msg]

#puts "Disposition = $result"

set messages {
    "MSH|^~\\&|EPIC|TSH|DOWNSTREAM|SYSTEM|202609302100||ADT^A08|12345|P|2.3\rPID|1||123456^^^TSH^MR||SMITH^JOHN||19800101|M"
    "MSH|^~\\&|EPIC|TSH|DOWNSTREAM|SYSTEM|202609302100||ADT^A31|12345|P|2.3\rPID|1||123456^^^TSH^MR||SMITH^JOHN||19800101|M"
    "MSH|^~\\&|EPIC|TSH|DOWNSTREAM|SYSTEM|202609302100||ADT^A03|12345|P|2.3\rPID|1||123456^^^TSH^MR||SMITH^JOHN||19800101|M"
    "MSH|^~\\&|EPIC|TSH|DOWNSTREAM|SYSTEM|202609302100||ORU^R01|12345|P|2.3\rPID|1||123456^^^TSH^MR||SMITH^JOHN||19800101|M"
}

foreach msg $messages {

    puts "-----------------------------"

    set result [filter_message $msg]

    puts "Disposition = $result"
}
