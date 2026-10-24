# args is a Tcl list
# accept whatever arguments Cloverleaf passes me, collect them into the Tcl list named args, and then inspect/process that list.
proc interfaceEngine {first {second ""} args} {

    if {$second eq ""} {

        puts "One argument: $first"
        return 1

    } elseif {[llength $args] == 0} {

        puts "Two arguments: $first $second"
        return 2

    } else {

        puts "Many arguments:"
        puts "first  = $first"
        puts "second = $second"
        puts "args   = $args"

        return many
    }
}

interfaceEngine hapi
puts ""
interfaceEngine hl7 fhir
puts ""
interfaceEngine hl7 fhir api hapi
puts ""
interfaceEngine Mirth OIE Cloverleaf Rhapsody BridgeLink NextGen

proc segment {a {b 1} {c 2}} {
    puts "$a $b $c"
}
puts ""
segment MSH
puts ""
segment MSH PID PV1 
