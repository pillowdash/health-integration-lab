set patientName "SMITH^JOHN"
set mrn "123456"
set facility "TSH"
#
#
# facility   → variable name
# $facility  → value of variable

puts "Patient Name: $patientName"
puts "MRN: $mrn"
puts "Facility: $facility"


# 'string' is the Tcl command.
# 'length' is the first argument to 'string'; 'string' interprets it as a subcommand.
# $patientName is the second argument.
# [ ... ] executes the command and substitutes its return value here.
puts "Length: [string length $patientName]"
