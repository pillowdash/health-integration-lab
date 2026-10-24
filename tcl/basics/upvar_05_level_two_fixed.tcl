# Top-level variables
set messageStatus "RECEIVED"
set oruMessage "MSH|^~\\&|LAB|TSH|EPIC|TSH|202610050900||ORU^R01|MSG1001|P|2.5"

proc processMessage {} {
    finalizeMessage
}

proc finalizeMessage {} {

    # Go TWO levels up:
    #
    # finalizeMessage
    #       ↑ level 1
    # processMessage
    #       ↑ level 2
    # top level
    #
    # Find the variable literally named "messageStatus".
    # Locally call it "status".
    upvar 2 messageStatus status

    puts "Before = $status"

    set status "COMPLETE"

    puts "After  = $status"
}

processMessage

puts "Top-level messageStatus = $messageStatus"
