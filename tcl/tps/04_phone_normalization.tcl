proc normalize_phone {phone country} {

    puts "Original phone = $phone"
    puts "Country        = $country"

    if {$country eq "CAN" || $country eq "USA"} {

        # Remove common formatting characters
        set normalized [string map {
            "(" ""
            ")" ""
            "-" ""
            " " ""
        } $phone]

        return $normalized

    } else {

        # For international numbers, preserve structure for now
        return $phone
    }
}

#set msg "MSH|^~\\&|EPIC|TSH|OLIS|OLIS|202610011000||ADT^A08|12345|P|2.3\rPID|1||123456^^^TSH^MR||SMITH^JOHN||19800101|M|||123 MAIN ST^^MARKHAM^ON^L3R1A1^CAN||(905) 555-1234|(416) 555-9876"
set msg "MSH|^~\\&|EPIC|TSH|OLIS|OLIS|202610011000||ADT^A08|12345|P|2.3\rPID|1||123456^^^TSH^MR||ZHANG^WEI||19800101|M|||1 ROAD^^BEIJING^^100000^CHN||+86 10 5555 1234|+86 138 1234 5678"

set segments [split $msg "\r"]

foreach segment $segments {

    set fields [split $segment "|"]

    if {[lindex $fields 0] eq "PID"} {

        set pid11 [lindex $fields 11]
        set pid13 [lindex $fields 13]
        set pid14 [lindex $fields 14]

        puts "PID-11 = $pid11"
        puts "PID-13 = $pid13"
        puts "PID-14 = $pid14"
    }
}

set addressComponents [split $pid11 "^"]

set country [lindex $addressComponents 5]

puts "Country = $country"

set newPid13 [normalize_phone $pid13 $country]
set newPid14 [normalize_phone $pid14 $country]

puts "New PID-13 = $newPid13"
puts "New PID-14 = $newPid14"
