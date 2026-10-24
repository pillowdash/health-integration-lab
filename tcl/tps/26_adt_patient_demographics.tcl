# ============================================================
# LESSON 26
#
# ADT Patient Demographics Processing
#
# Topics:
#
#   MSH-9 message type / trigger
#   PID-3 repetitions (CX datatype)
#   PID-13 / PID-14 repetitions (XTN datatype)
#   PV1 context
#   A08 / A31 filtering
#   Selecting identifiers by assigning authority / type
#   Country-aware phone handling
#   Preserve original HL7 structure
#
# ============================================================


# ============================================================
# LOAD LIBRARY
# ============================================================

set scriptDir \
    [file dirname [file normalize [info script]]]

set tclRoot \
    [file normalize [file join $scriptDir ..]]

set libDir \
    [file join $tclRoot lib]

lappend auto_path $libDir


package require hl7utils

set msg [join [list \
    "MSH|^~\\&|EPIC|TSH|DOWNSTREAM|TSH|202610101600||ADT^A08|MSG26001|P|2.5" \
    "EVN|A08|202610101600" \
    "PID|1||123456^^^TSH^MR~998877^^^OHIP^JHN~E12345^^^EPIC^EPI||SMITH^JOHN||19800101|M|||123 MAIN ST^^MARKHAM^ON^L3R1A1^CAN||(905)555-1234^PRN^PH^^1^905^5551234~john.smith@example.com^NET^Internet|(416)555-9876^WPN^PH^^1^416^5559876||||||||||||||||N" \
    "PV1|1|O|ER^01^01^TSH||||1234^DOCTOR^JANE||||MED|||||||1234567|||||||||||||||||||||||||202610101530" \
] "\r"]

puts "============================================================"
puts "ORIGINAL ADT"
puts "============================================================"

puts [string map {"\r" "\n"} $msg]

puts ""
puts "============================================================"
puts "1. MESSAGE TYPE"
puts "============================================================"


set typeInfo \
    [hl7::get_message_type_components $msg]


set messageCode \
    [dict get $typeInfo messageCode]

set triggerEvent \
    [dict get $typeInfo triggerEvent]


puts "Message code  = $messageCode"
puts "Trigger event = $triggerEvent"	

proc is_supported_adt {msg} {

    set typeInfo \
        [hl7::get_message_type_components $msg]


    set messageCode \
        [dict get $typeInfo messageCode]

    set triggerEvent \
        [dict get $typeInfo triggerEvent]


    if {$messageCode ne "ADT"} {
        return 0
    }


    switch -exact -- $triggerEvent {

        A08 -
        A31 {

            return 1
        }


        default {

            return 0
        }
    }
}

puts "Supported ADT?"
puts [is_supported_adt $msg]


set pid3 \
    [hl7::get $msg "PID-3"]


puts ""
puts "PID-3 raw:"
puts $pid3

set identifiers \
    [split $pid3 "~"]


puts ""
puts "PID-3 repetitions:"

foreach identifier $identifiers {

    puts "  <$identifier>"
}


proc parse_cx {cxValue} {

    set components \
        [split $cxValue "^"]


    set id \
        [lindex $components 0]

    set assigningAuthority \
        [lindex $components 3]

    set identifierType \
        [lindex $components 4]


    return [dict create \
        id $id \
        assigningAuthority $assigningAuthority \
        identifierType $identifierType]
}

foreach identifier $identifiers {

    set cx \
        [parse_cx $identifier]


    puts ""
    puts "ID                  = [dict get $cx id]"
    puts "Assigning authority = [dict get $cx assigningAuthority]"
    puts "Identifier type     = [dict get $cx identifierType]"
}


proc find_identifier {
    pid3Value
    wantedAuthority
    wantedType
} {

    foreach repetition \
        [split $pid3Value "~"] {


        set cx \
            [parse_cx $repetition]


        set authority \
            [dict get \
                $cx \
                assigningAuthority]

        set type \
            [dict get \
                $cx \
                identifierType]


        if {$authority eq $wantedAuthority &&
            $type eq $wantedType} {

            return \
                [dict get $cx id]
        }
    }


    return ""
}

set tshMrn \
    [find_identifier \
        $pid3 \
        TSH \
        MR]


puts ""
puts "TSH MRN = <$tshMrn>"

set healthNumber \
    [find_identifier \
        $pid3 \
        OHIP \
        JHN]


puts "Health number = <$healthNumber>"

set homePhone \
    [hl7::get $msg "PID-13"]

set workPhone \
    [hl7::get $msg "PID-14"]


puts ""
puts "============================================================"
puts "2. TELEPHONE FIELDS"
puts "============================================================"

puts "PID-13 = $homePhone"
puts "PID-14 = $workPhone"


proc parse_xtn {xtnValue} {

    set components \
        [split $xtnValue "^"]


    return [dict create \
        value \
            [lindex $components 0] \
        useCode \
            [lindex $components 1] \
        equipmentType \
            [lindex $components 2] \
        countryCode \
            [lindex $components 4] \
        areaCode \
            [lindex $components 5] \
        localNumber \
            [lindex $components 6]]
}

puts ""
puts "PID-13 repetitions:"


foreach repetition [split $homePhone "~"] {

    set xtn \
        [parse_xtn $repetition]


    puts ""

    puts "Value          = [dict get $xtn value]"
    puts "Use code       = [dict get $xtn useCode]"
    puts "Equipment type = [dict get $xtn equipmentType]"
}


proc normalize_nanp_phone {xtnValue} {

    set parts \
        [split $xtnValue "^"]

    set useCode \
        [lindex $parts 1]

    set equipmentType \
        [lindex $parts 2]


    # Do not modify email/Internet repetitions.
    if {$equipmentType eq "Internet" ||
        $useCode eq "NET"} {

        return $xtnValue
    }


    set countryCode \
        [lindex $parts 4]

    set areaCode \
        [lindex $parts 5]

    set localNumber \
        [lindex $parts 6]


    # For this lesson, only normalize country code 1.
    if {$countryCode ne "1"} {

        return $xtnValue
    }


    set digits \
        [regsub -all {[^0-9]} \
            "$areaCode$localNumber" \
            ""]


    if {[string length $digits] != 10} {

        return $xtnValue
    }


    set normalized \
        "+1$digits"


    lset parts 0 $normalized


    return [join $parts "^"]
}

proc normalize_xtn_field {fieldValue} {

    set output {}


    foreach repetition \
        [split $fieldValue "~"] {


        lappend output \
            [normalize_nanp_phone \
                $repetition]
    }


    return [join $output "~"]
}

puts ""
puts "PID-13 normalized:"

puts \
    [normalize_xtn_field \
        $homePhone]



proc transform_adt_demographics {msg} {

    set output {}


    foreach segment [split $msg "\r"] {

        set segmentType \
            [hl7::segment_name $segment]


        if {$segmentType eq "PID"} {

            # ----------------------------------------
            # PID-13
            # ----------------------------------------

            set pid13 \
                [hl7::get_from_segment \
                    $segment \
                    "PID-13"]


            if {$pid13 ne ""} {

                set pid13 \
                    [normalize_xtn_field \
                        $pid13]


                set segment \
                    [hl7::set_in_segment \
                        $segment \
                        "PID-13" \
                        $pid13]
            }


            # ----------------------------------------
            # PID-14
            # ----------------------------------------

            set pid14 \
                [hl7::get_from_segment \
                    $segment \
                    "PID-14"]


            if {$pid14 ne ""} {

                set pid14 \
                    [normalize_xtn_field \
                        $pid14]


                set segment \
                    [hl7::set_in_segment \
                        $segment \
                        "PID-14" \
                        $pid14]
            }
        }


        lappend output $segment
    }


    return [join $output "\r"]
}

set transformed \
    [transform_adt_demographics $msg]


puts ""
puts "============================================================"
puts "3. TRANSFORMED ADT"
puts "============================================================"

puts [string map {"\r" "\n"} $transformed]

	
proc safe_transform_adt {msg} {

    set typeInfo \
        [hl7::get_message_type_components $msg]


    set messageCode \
        [dict get $typeInfo messageCode]

    set triggerEvent \
        [dict get $typeInfo triggerEvent]


    if {$messageCode ne "ADT"} {

        return [dict create \
            disposition CONTINUE \
            message $msg \
            reason "Not an ADT message"]
    }


    switch -exact -- $triggerEvent {

        A08 -
        A31 {

            # supported
        }


        default {

            return [dict create \
                disposition CONTINUE \
                message $msg \
                reason \
                    "ADT trigger $triggerEvent not handled"]
        }
    }


    if {[catch {

        set transformed \
            [transform_adt_demographics \
                $msg]

    } err options]} {

        return [dict create \
            disposition ERROR \
            message $msg \
            error $err]
    }


    return [dict create \
        disposition CONTINUE \
        message $transformed \
        reason "ADT demographics transformed"]
}

set result \
    [safe_transform_adt $msg]

set disposition \
    [dict get $result disposition]


puts ""
puts "Disposition:"
puts $disposition


if {$disposition eq "ERROR"} {

    puts "Error:"
    puts [dict get $result error]

} else {

    puts "Reason:"
    puts [dict get $result reason]
}

set patientClass \
    [hl7::get $msg "PV1-2"]

set location \
    [hl7::get $msg "PV1-3"]


puts ""
puts "============================================================"
puts "4. PV1 CONTEXT"
puts "============================================================"

puts "Patient class = $patientClass"
puts "Location      = $location"


set locationParts \
    [split $location "^"]


set pointOfCare \
    [lindex $locationParts 0]

set room \
    [lindex $locationParts 1]

set bed \
    [lindex $locationParts 2]

set facility \
    [lindex $locationParts 3]


puts "Point of care = $pointOfCare"
puts "Room          = $room"
puts "Bed           = $bed"
puts "Facility      = $facility"

proc summarize_adt {msg} {

    set pid3 \
        [hl7::get $msg "PID-3"]


    set mrn \
        [find_identifier \
            $pid3 \
            TSH \
            MR]


    set healthNumber \
        [find_identifier \
            $pid3 \
            OHIP \
            JHN]


    set patientClass \
        [hl7::get $msg "PV1-2"]


    set location \
        [hl7::get $msg "PV1-3"]


    return [dict create \
        mrn $mrn \
        healthNumber $healthNumber \
        patientClass $patientClass \
        location $location]
}


set summary \
    [summarize_adt $msg]


puts ""
puts "============================================================"
puts "5. ADT SUMMARY"
puts "============================================================"

puts "MRN            = [dict get $summary mrn]"
puts "Health number  = [dict get $summary healthNumber]"
puts "Patient class  = [dict get $summary patientClass]"
puts "Location       = [dict get $summary location]"
