proc parse_xtn {xtnValue} {

    set components [split $xtnValue "^"]

    set telephoneNumber      [lindex $components 0]
    set telecommunicationUse [lindex $components 1]
    set equipmentType        [lindex $components 2]
    set countryCode          [lindex $components 4]
    set areaCode             [lindex $components 5]
    set localNumber          [lindex $components 6]

    puts "Telephone Number : $telephoneNumber"
    puts "Use Code         : $telecommunicationUse"
    puts "Equipment Type   : $equipmentType"
    puts "Country Code     : $countryCode"
    puts "Area Code        : $areaCode"
    puts "Local Number     : $localNumber"
}

proc parse_xtn_field {fieldValue} {

    set repetitions [split $fieldValue "~"]

    set repetitionNumber 1

    foreach xtn $repetitions {

        puts ""
        puts "XTN repetition $repetitionNumber"

        parse_xtn $xtn

        incr repetitionNumber
    }
}

proc normalize_xtn {xtnValue} {

    set components [split $xtnValue "^"]

    set countryCode [lindex $components 4]
    set areaCode    [lindex $components 5]
    set localNumber [lindex $components 6]

    if {$countryCode eq "1" &&
        $areaCode ne "" &&
        $localNumber ne ""} {

        set normalized "+$countryCode$areaCode$localNumber"

        lset components 0 $normalized
    }

    return [join $components "^"]
}

proc normalize_xtn_field {fieldValue} {

    set repetitions [split $fieldValue "~"]
    set newRepetitions {}

    foreach xtn $repetitions {

        set newXtn [normalize_xtn $xtn]

        lappend newRepetitions $newXtn
    }

    return [join $newRepetitions "~"]
}

proc parse_xtn_ealier_version {xtnValue} {

    set components [split $xtnValue "^"]

    puts "XTN raw value: $xtnValue"

    # indx
    set index 0

    foreach component $components {
        # indx
        puts "  component $index = $component"
        # indx
        incr index
    }
}

set phone "(905)555-1234^PRN^PH^^1^905^5551234"

parse_xtn $phone

set pid13 "(905)555-1234^PRN^PH^^1^905^5551234~mark@example.com^NET^Internet"

parse_xtn_field $pid13


set msg "MSH|^~\\&|EPIC|TSH|OLIS|OLIS|202610011100||ADT^A08|12345|P|2.3\rPID|1||123456^^^TSH^MR||SMITH^JOHN||19800101|M|||123 MAIN ST^^MARKHAM^ON^L3R1A1^CAN||(905)555-1234^PRN^PH^^1^905^5551234~mark@example.com^NET^Internet|(416)555-9876^WPN^PH^^1^416^5559876"


set segments [split $msg "\r"]

foreach segment $segments {

    set fields [split $segment "|"]

    if {[lindex $fields 0] eq "PID"} {

        set pid13 [lindex $fields 13]
        set pid14 [lindex $fields 14]

        puts ""
        puts "=== PID-13 ==="
        parse_xtn_field $pid13

        puts ""
        puts "=== PID-14 ==="
        parse_xtn_field $pid14

	set newPid13 [normalize_xtn_field $pid13]
        set newPid14 [normalize_xtn_field $pid14]

        puts ""
        puts "=== PID-13 after normalize ==="
        parse_xtn_field $newPid13

        puts ""
        puts "=== PID-14 after normalize  ==="
        parse_xtn_field $newPid14


    }
}
