set msg "MSH|^~\\&|EPIC|TSH|OLIS|OLIS|202609302100||ADT^A08|12345|P|2.3\rPID|1||123456^^^TSH^MR||SMITH^JOHN||19800101|M"

puts "Complete HL7 message but weird:"
puts $msg

puts ""
puts "Complete HL7 message:"
puts [string map {"\r" "\n"} $msg]

puts ""
puts "Segments:"

set segments [split $msg "\r"]

foreach segment $segments {
    puts $segment
}


foreach segment $segments {

    set fields [split $segment "|"]

    set segmentName [lindex $fields 0]

    if {$segmentName eq "PID"} {

        set pid3 [lindex $fields 3]
        set pid5 [lindex $fields 5]
        set pid7 [lindex $fields 7]
        set pid8 [lindex $fields 8]

        puts "PID-3 = $pid3"
        puts "PID-5 = $pid5"
	set components [split $pid3 "^"]

	puts "MRN:       [lindex $components 0]"
	puts "Authority: [lindex $components 3]"
	puts "Type:      [lindex $components 4]"
	set components [split $pid5 "^"]

	puts "Last Name: [lindex $components 0]"
	puts "First Name: [lindex $components 1]"

	puts "DOB:     $pid7 "

	puts "Sex:     $pid8 "
    }
}
