# ============================================================
# UPVAR 
# ============================================================


# ============================================================
# PART 1
#
# Simple upvar:
# A procedure modifies a variable that belongs to its caller.
#
# Imagine these are numeric OBX-5 result values.
# ============================================================

proc normalizeNumericResult {resultVariableName incomingValue} {

    # resultVariableName contains the NAME of a caller variable.
    #
    # Example:
    #
    #     resultVariableName = potassiumValue
    #
    # upvar 1 means:
    #
    #     Look ONE call level above me
    #     Find the variable named potassiumValue
    #     Create a local alias named resultValue
    #
    upvar 1 $resultVariableName resultValue


    # For this learning example, force negative result values
    # to become positive.
    #
    # This is only to demonstrate upvar.
    if {$incomingValue < 0} {

        set resultValue [expr {-$incomingValue}]

    } else {

        set resultValue $incomingValue
    }


    # Because resultValue is an alias, the caller's variable
    # has already been changed.
    return $resultValue
}


# These variables exist at top level.
set potassiumValue 0
set sodiumValue 0


# IMPORTANT:
#
# We pass the VARIABLE NAME:
#
#     potassiumValue
#
# not:
#
#     $potassiumValue
#
normalizeNumericResult potassiumValue 5.8
normalizeNumericResult sodiumValue -140


puts "=== RESULT VALUES ==="
puts "Potassium OBX-5 = $potassiumValue"
puts "Sodium OBX-5    = $sodiumValue"



# ============================================================
# PART 2
#
# Nested upvar:
#
# We will use:
#
#     upvar 1
#     upvar 2
#
# This demonstrates caller and caller's caller.
# ============================================================


# Imagine this is an incoming ORU message.
set oruMessage \
"MSH|^~\\&|LAB|TSH|EPIC|TSH|202610050900||ORU^R01|MSG1001|P|2.5\rOBR|1|||BMP^Basic Metabolic Panel\rOBX|1|NM|K^Potassium||5.8|mmol/L|3.5-5.1|H|||P"


# This represents some processing state maintained by
# our interface/TPS logic.
set interfaceStatus "RECEIVED"



# ============================================================
# INNER PROCEDURE
#
# This procedure is called BY processOruMessage.
# ============================================================

proc finalizeOruMessage {messageAliasName} {

    # --------------------------------------------------------
    # upvar 1
    #
    # Look ONE level above:
    #
    #     finalizeOruMessage
    #             ↑
    #       processOruMessage
    #
    # messageAliasName contains:
    #
    #     workingMessage
    #
    # So this aliases processOruMessage's variable
    # "workingMessage" as local variable "msg".
    # --------------------------------------------------------

    upvar 1 $messageAliasName msg


    # --------------------------------------------------------
    # upvar 2
    #
    # Look TWO levels above:
    #
    #     finalizeOruMessage      level 0
    #             ↑
    #     processOruMessage       level 1
    #             ↑
    #     top-level script        level 2
    #
    # At top level we have:
    #
    #     interfaceStatus
    #
    # Locally we will call it:
    #
    #     status
    # --------------------------------------------------------

    # Go up 2 call frames, find the variable literally named interfaceStatus, and make my local variable status an alias for it. 
    upvar 2 interfaceStatus status
    # does not require interfaceStatus to be passed as an argument.
    # interfaceStatus in this command is itself the name of the variable Tcl should look for two stack levels above.
    # 
    #

    puts ""
    puts "Inside finalizeOruMessage:"
    puts "  Interface status before = $status"


    # Modify the ORIGINAL top-level HL7 message.
    #
    # msg is an alias chain that ultimately points to
    # the top-level variable oruMessage.
    append msg "\rZXX|RESULT_FINALIZED"


    # Modify the top-level interfaceStatus.
    set status "COMPLETE"


    puts "  Interface status after  = $status"
}



# ============================================================
# OUTER PROCEDURE
# ============================================================

proc processOruMessage {messageVariableName} {

    # Suppose this procedure was called as:
    #
    #     processOruMessage oruMessage
    #
    # Therefore:
    #
    #     messageVariableName = "oruMessage"
    #
    # upvar 1 finds the caller's variable named oruMessage
    # and creates local alias workingMessage.
    #

    upvar 1 $messageVariableName workingMessage


    puts ""
    puts "Inside processOruMessage:"
    puts "  Message variable name = $messageVariableName"


    # We pass the NAME of our local alias:
    #
    #     workingMessage
    #
    # not its value.
    #
    # finalizeOruMessage will use upvar 1 to connect to it.
    finalizeOruMessage workingMessage
}



# ============================================================
# MAIN PROGRAM
# ============================================================

puts ""
puts "=== BEFORE PROCESSING ==="

puts "Interface Status = $interfaceStatus"

puts ""
puts [string map {"\r" "\n"} $oruMessage]


# Pass the VARIABLE NAME.
processOruMessage oruMessage


puts ""
puts "=== AFTER PROCESSING ==="

puts "Interface Status = $interfaceStatus"

puts ""
puts [string map {"\r" "\n"} $oruMessage]
