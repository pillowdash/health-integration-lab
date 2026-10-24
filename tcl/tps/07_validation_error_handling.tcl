proc validate_xtn {xtnValue patientCountry} {

    set warnings {}
    set errors {}

    set components [split $xtnValue "^"]

    set telephoneNumber      [lindex $components 0]
    set telecommunicationUse [lindex $components 1]
    set equipmentType        [lindex $components 2]
    set countryCode          [lindex $components 4]
    set areaCode             [lindex $components 5]
    set localNumber          [lindex $components 6]

    # Email / network contact: do not apply phone validation
    if {$telecommunicationUse eq "NET" ||
        $equipmentType eq "Internet"} {

        return [dict create \
            status VALID \
            warnings $warnings \
            errors $errors]
    }

    # Basic required-value check
    if {$telephoneNumber eq "" &&
        $localNumber eq ""} {

        lappend errors "XTN contains no telephone number"
    }

    # NANP-specific checks
    if {$patientCountry eq "CAN" ||
        $patientCountry eq "USA"} {

        if {$countryCode eq ""} {
            lappend warnings "XTN.5 country code is missing"
        }

        if {$areaCode eq ""} {
            lappend warnings "XTN.6 area code is missing"
        }

        if {$localNumber eq ""} {
            lappend warnings "XTN.7 local number is missing"
        }

        if {$countryCode ne "" && $countryCode ne "1"} {
            lappend warnings \
                "CAN/USA patient has non-NANP country code: $countryCode"
        }
    }

    # Simple international consistency check
    if {$patientCountry ne "CAN" &&
        $patientCountry ne "USA"} {

        if {[string match "+86*" $telephoneNumber] &&
            $countryCode eq "1"} {

            lappend warnings \
                "Phone starts with +86 but XTN.5 country code is 1"
        }
    }

    if {[llength $errors] > 0} {
        set status ERROR
    } elseif {[llength $warnings] > 0} {
        set status WARNING
    } else {
        set status VALID
    }

    return [dict create \
        status $status \
        warnings $warnings \
        errors $errors]
}


proc validate_xtn_field {fieldValue patientCountry fieldName} {

    set results {}

    set repetitions [split $fieldValue "~"]
    set repetitionNumber 1

    foreach xtn $repetitions {

        set result [validate_xtn $xtn $patientCountry]

        dict set result field $fieldName
        dict set result repetition $repetitionNumber
        dict set result value $xtn

        lappend results $result

        incr repetitionNumber
    }

    return $results
}

set xtn "+86 10 5555 1234^PRN^PH^^1^905^5551234"

set result [validate_xtn $xtn "CHN"]

puts "Status = [dict get $result status]"
puts "Warnings = [dict get $result warnings]"
puts "Errors = [dict get $result errors]"


set pid13 "+86 10 5555 1234^PRN^PH^^1^905^5551234~mark@example.com^NET^Internet"

set results [validate_xtn_field $pid13 "CHN" "PID-13"]

foreach result $results {

    puts ""
    puts "Field      = [dict get $result field]"
    puts "Repetition = [dict get $result repetition]"
    puts "Status     = [dict get $result status]"
    puts "Value      = [dict get $result value]"

    foreach warning [dict get $result warnings] {
        puts "WARNING: $warning"
    }

    foreach error [dict get $result errors] {
        puts "ERROR: $error"
    }
}

puts ""

# Tcl catch concept : trap th error
if {[catch {
    expr {10 / 0}
} err]} {

    puts "Caught error: $err"
}
