proc normalize_xtn {xtnValue patientCountry} {

    set components [split $xtnValue "^"]

    set telephoneNumber      [lindex $components 0]
    set telecommunicationUse [lindex $components 1]
    set equipmentType        [lindex $components 2]
    set countryCode          [lindex $components 4]
    set areaCode             [lindex $components 5]
    set localNumber          [lindex $components 6]

    puts "XTN value       = $xtnValue"
    puts "Use code        = $telecommunicationUse"
    puts "Equipment type  = $equipmentType"

    # Do not modify email / network contact repetitions
    if {$telecommunicationUse eq "NET" ||
        $equipmentType eq "Internet"} {

        puts "Action          = preserve non-phone contact"
        return $xtnValue
    }

    # Canada / USA
    if {$patientCountry eq "CAN" || $patientCountry eq "USA"} {

        if {$countryCode ne "" &&
            $areaCode ne "" &&
            $localNumber ne ""} {

            set normalized "+$countryCode$areaCode$localNumber"

            lset components 0 $normalized

            puts "Action          = normalize NANP phone"
            puts "Normalized      = $normalized"
        }

    } else {

        puts "Action          = preserve international number"
    }

    return [join $components "^"]
}


proc normalize_xtn_field {fieldValue patientCountry} {

    set repetitions [split $fieldValue "~"]
    set newRepetitions {}

    foreach xtn $repetitions {

        set newXtn [normalize_xtn $xtn $patientCountry]

        lappend newRepetitions $newXtn
    }

    return [join $newRepetitions "~"]
}


proc transform_message {msg} {

    set segments [split $msg "\r"]
    set newSegments {}

    foreach segment $segments {

        set fields [split $segment "|"]

        if {[lindex $fields 0] eq "PID"} {

            set pid11 [lindex $fields 11]

            set addressComponents [split $pid11 "^"]
            set patientCountry [lindex $addressComponents 5]

            puts ""
            puts "Patient country = $patientCountry"

            set pid13 [lindex $fields 13]
            set pid14 [lindex $fields 14]

            set newPid13 [normalize_xtn_field $pid13 $patientCountry]
            set newPid14 [normalize_xtn_field $pid14 $patientCountry]

            lset fields 13 $newPid13
            lset fields 14 $newPid14

            set segment [join $fields "|"]
        }

        lappend newSegments $segment
    }

    return [join $newSegments "\r"]
}


#set msg "MSH|^~\\&|EPIC|TSH|OLIS|OLIS|202610011200||ADT^A08|12345|P|2.3\rPID|1||123456^^^TSH^MR||SMITH^JOHN||19800101|M|||123 MAIN ST^^MARKHAM^ON^L3R1A1^CAN||(905)555-1234^PRN^PH^^1^905^5551234~mark@example.com^NET^Internet|(416)555-9876^WPN^PH^^1^416^5559876"
set msg "MSH|^~\\&|EPIC|TSH|OLIS|OLIS|202610011200||ADT^A08|12345|P|2.3\rPID|1||123456^^^TSH^MR||SMITH^JOHN||19800101|M|||123 MAIN ST^^MARKHAM^ON^L3R1A1^CHN||+86 10 5555 1234^PRN^PH^^1^905^5551234~mark@example.com^NET^Internet|(416)555-9876^WPN^PH^^1^416^5559876"

set transformed [transform_message $msg]

puts ""
puts "=== ORIGINAL ==="
puts [string map {"\r" "\n"} $msg]

puts ""
puts "=== TRANSFORMED ==="
puts [string map {"\r" "\n"} $transformed]
