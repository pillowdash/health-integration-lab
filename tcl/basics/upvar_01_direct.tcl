# ------------------------------------------------------------
# CASE 1
#
# Pass the NAME of a variable directly to a procedure.
#
# Important:
#
#     modify_message hl7msg
#
# We pass "hl7msg", NOT "$hl7msg".
#
# The procedure uses upvar to create a local alias to the
# caller's variable.
# ------------------------------------------------------------

# scenario - I already know the variable name

# Our HL7 message variable
set hl7msg "MSH|^~\\&|EPIC|TSH|TEST|TEST|202610041200||ADT^A08|12345|P|2.5\rPID|1||123456^^^TSH^MR||SMITH^JOHN"


proc modify_message {variableName} {

    # variableName contains:
    #
    #     hl7msg
    #
    # upvar says:
    #
    # "Find the variable named hl7msg in my caller's scope
    #  and give me a local alias called msg."
    #
    upvar 1 $variableName msg


    puts "Inside procedure:"
    puts "variableName = $variableName"

    # msg is now another name for the caller's hl7msg variable
    append msg "\rZXX|Modified by Tcl"
}


puts "=== BEFORE ==="
puts [string map {"\r" "\n"} $hl7msg]

puts ""

# IMPORTANT:
# We are passing the VARIABLE NAME.
modify_message hl7msg

puts ""
puts "=== AFTER ==="
puts [string map {"\r" "\n"} $hl7msg]
