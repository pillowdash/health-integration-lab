# ============================================================
# ORU transformation rules
# ============================================================

package require hl7utils

namespace eval oru {}


proc oru::transform {msg threshold} {

    set output {}


    foreach segment [split $msg "\r"] {

        set segmentType \
            [hl7::segment_name $segment]


        # Anything except OBX passes unchanged.
        if {$segmentType ne "OBX"} {

            lappend output $segment
            continue
        }


        set code \
            [hl7::get_from_segment \
                $segment \
                "OBX-3.1"]

        set value \
            [hl7::get_from_segment \
                $segment \
                "OBX-5"]


        # Potassium only.
        if {$code eq "K" &&
            [string is double -strict $value] &&
            $value > $threshold} {

            set segment \
                [hl7::set_in_segment \
                    $segment \
                    "OBX-8" \
                    "H"]
        }


        lappend output $segment
    }


    return [join $output "\r"]
}


package provide orurules 1.0
