set oruStatus "RECEIVED"
set siuStatus "RECEIVED"


puts "ORU status = $oruStatus"
puts "SIU status = $siuStatus"

proc processMessage {messageType} {

    finalizeMessage $messageType
}

proc finalizeMessage {messageType} {

    # Decide which VARIABLE NAME we want to access
    if {$messageType eq "ORU"} {
        set targetVariableName "oruStatus"
    } elseif {$messageType eq "SIU"} {
        set targetVariableName "siuStatus"
    } else {
        error "Unsupported message type"
    }

    puts "Target variable name = $targetVariableName"

    # Go 2 levels up and look for the variable whose NAME
    # is stored in targetVariableName.
    upvar 2 $targetVariableName status

    set status "COMPLETE"
}

processMessage ORU

puts "ORU status = $oruStatus"
puts "SIU status = $siuStatus"

processMessage SIU

puts "ORU status = $oruStatus"
puts "SIU status = $siuStatus"
