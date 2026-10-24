namespace eval xtn {

    proc normalize {xtnValue patientCountry} {

        set components [split $xtnValue "^"]

        set telephoneNumber      [lindex $components 0]
        set telecommunicationUse [lindex $components 1]
        set equipmentType        [lindex $components 2]
        set countryCode          [lindex $components 4]
        set areaCode             [lindex $components 5]
        set localNumber          [lindex $components 6]

        if {$telecommunicationUse eq "NET" ||
            $equipmentType eq "Internet"} {

            return $xtnValue
        }

        if {$patientCountry eq "CAN" ||
            $patientCountry eq "USA"} {

            if {$countryCode ne "" &&
                $areaCode ne "" &&
                $localNumber ne ""} {

                set normalized "+$countryCode$areaCode$localNumber"

                lset components 0 $normalized
            }
        }

        return [join $components "^"]
    }


    proc normalize_field {fieldValue patientCountry} {

        set repetitions [split $fieldValue "~"]
        set newRepetitions {}

        foreach value $repetitions {

            lappend newRepetitions \
                [normalize $value $patientCountry]
        }

        return [join $newRepetitions "~"]
    }
}

package provide xtn 1.0
