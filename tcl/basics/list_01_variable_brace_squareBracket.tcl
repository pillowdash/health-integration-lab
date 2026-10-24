set patientName "SMITH JOHN"

# Use { ... } when writing a fixed literal list. 
# Use [list ...] when constructing a list from variables or computed values.

set x {$patientName 123456}
set y [list $patientName 123456]

puts "use curly brace:" 
puts $x
puts "use square brakcet:" 
puts $y


set observation "K^Potassium"
set result "5.8"
set note "Result verified by laboratory"

set resultData [list $observation $result $note]

puts [llength $resultData]

puts [lindex $resultData 2]


set b [list a b {c d e} {f {g h}}]
# produces essentially the same list value as
set b [list a b {c d e} {f {g h}}]
