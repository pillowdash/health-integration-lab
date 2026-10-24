set interfaceName "OLIS_OUT"
set messageCount 0

proc processOru {msg} {

    # global messageStatus
    #        ↑
    # make the global variable messageStatus
    # available under the same name in this proc
    global interfaceName messageCount

    puts "Interface = $interfaceName"

    incr messageCount

    puts "Processing message:"
    puts [string map {"\r" "\n"} $msg]
}

set msg "MSH|^~\\&|LAB|TSH|EPIC|TSH|202610050900||ORU^R01|MSG1001|P|2.5"

processOru $msg
processOru $msg

puts "Total processed = $messageCount"


set messageCount 0
proc processMsg {msg} {

    # global variable named messageCount → alias count 
    upvar #0 messageCount count


    incr count

    puts "Processing message:"
    puts [string map {"\r" "\n"} $msg]
}

processMsg $msg
processMsg $msg

puts "Total processed = $messageCount"


set interfaceStatus "RECEIVED"

proc changeStatus {} {

    # Tcl's global namespace :: 
    # directly address the global variable without using global
    # the variable named interfaceStatus in the global namespace. 
    set ::interfaceStatus "COMPLETE"

    puts "Status = $::interfaceStatus"
}

changeStatus

puts $interfaceStatus
