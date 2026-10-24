# ============================================================
# LESSON 15
#
# ORU traversal + conditional transformation
#
# Skills:
#
#   - segment traversal
#   - OBR/OBX grouping
#   - higher-level HL7 helpers
#   - conditional transformation
#   - numeric validation
#   - preserving message structure
#
# Scenario:
#
#   If:
#
#       OBX-3.1 = K
#
#   and:
#
#       OBX-5 > 5.5
#
#   then:
#
#       OBX-8 = H
#
#   and add:
#
#       NTE|1||Potassium above interface threshold
#
# ============================================================
lappend auto_path [file normalize "tcl/lib"]
package require hl7utils

# ------------------------------------------------------------
# HL7 TEST MESSAGE
# ------------------------------------------------------------

set msg [join [list \
    "MSH|^~\\&|EPIC|TSH|LAB|TSH|202610061900||ORU^R01|MSG15001|P|2.5" \
    "PID|1||123456^^^TSH^MR||SMITH^JOHN||19800101|M" \
    "OBR|1|ORD1001|LAB1001|CBC^Complete Blood Count" \
    "OBX|1|NM|WBC^White Blood Cells||7.4|10*9/L|4.0-11.0|N|||F" \
    "OBX|2|NM|HGB^Hemoglobin||145|g/L|120-160|N|||F" \
    "OBX|3|NM|PLT^Platelets||250|10*9/L|150-400|N|||F" \
    "OBR|2|ORD1002|LAB1002|BMP^Basic Metabolic Panel" \
    "OBX|1|NM|NA^Sodium||140|mmol/L|135-145|N|||F" \
    "OBX|2|NM|K^Potassium||5.8|mmol/L|3.5-5.1|N|||F" \
] "\r"]


puts "============================================================"
puts "ORIGINAL MESSAGE"
puts "============================================================"

puts [string map {"\r" "\n"} $msg]

# ============================================================
# HL7 HELPER NAMESPACE
# ============================================================

#namespace eval hl7 {}


proc hl7::get_obr_groups {msg} {

    set groups {}

    set currentGroup {}


    foreach segment [split $msg "\r"] {

        set segmentType [hl7::segment_name $segment]


        switch -exact -- $segmentType {

            OBR {

                # Finish previous OBR group.
                if {$currentGroup ne ""} {
                    lappend groups $currentGroup
                }


                set currentGroup [dict create \
                    obr $segment \
                    children {}]
            }


            OBX -
            NTE {

                if {$currentGroup ne ""} {

                    dict lappend currentGroup \
                        children \
                        $segment
                }
            }
        }
    }


    # Don't forget final group.
    if {$currentGroup ne ""} {
        lappend groups $currentGroup
    }


    return $groups
}

puts ""
puts "============================================================"
puts "OBR GROUPS"
puts "============================================================"


set groups [hl7::get_obr_groups $msg]


set groupNumber 0


foreach group $groups {

    incr groupNumber


    set obr [dict get $group obr]

    set panelCode \
        [hl7::get_from_segment $obr "OBR-4.1"]

    set panelName \
        [hl7::get_from_segment $obr "OBR-4.2"]


    puts ""
    puts "GROUP $groupNumber"

    puts "Panel code = $panelCode"
    puts "Panel name = $panelName"


    foreach child [dict get $group children] {

        if {[hl7::segment_name $child] ne "OBX"} {
            continue
        }


        set observationCode \
            [hl7::get_from_segment $child "OBX-3.1"]

        set observationName \
            [hl7::get_from_segment $child "OBX-3.2"]

        set value \
            [hl7::get_from_segment $child "OBX-5"]

        set flag \
            [hl7::get_from_segment $child "OBX-8"]


        puts [format \
            "  %-4s %-22s value=%-6s flag=%s" \
            $observationCode \
            $observationName \
            $value \
            $flag]
    }
}


proc transform_obx {obx} {

    set observationCode \
        [hl7::get_from_segment $obx "OBX-3.1"]

    set value \
        [hl7::get_from_segment $obx "OBX-5"]


    # --------------------------------------------------------
    # Only transform Potassium.
    # --------------------------------------------------------

    if {$observationCode ne "K"} {

        return [dict create \
            segment $obx \
            addNte 0]
    }


    # --------------------------------------------------------
    # Validate OBX-5 before numeric comparison.
    # --------------------------------------------------------

    if {![string is double -strict $value]} {

        puts "WARNING: Potassium OBX-5 <$value> is not numeric"

        return [dict create \
            segment $obx \
            addNte 0]
    }


    # --------------------------------------------------------
    # Business rule:
    #
    # Potassium > 5.5
    #
    #     OBX-8 = H
    #
    #     add NTE
    # --------------------------------------------------------

    if {$value > 5.5} {

        set obx \
            [hl7::set_in_segment $obx "OBX-8" "H"]


        return [dict create \
            segment $obx \
            addNte 1]
    }


    return [dict create \
        segment $obx \
        addNte 0]
}


proc transform_oru {msg} {

    set outputSegments {}


    foreach segment [split $msg "\r"] {

        set segmentType \
            [hl7::segment_name $segment]


        # ----------------------------------------------------
        # Anything other than OBX:
        #
        # simply copy unchanged.
        # ----------------------------------------------------

        if {$segmentType ne "OBX"} {

            lappend outputSegments $segment

            continue
        }


        # ----------------------------------------------------
        # Transform OBX
        # ----------------------------------------------------

        set result \
            [transform_obx $segment]


        set newObx \
            [dict get $result segment]


        lappend outputSegments $newObx


        # ----------------------------------------------------
        # Optionally add NTE immediately after this OBX.
        # ----------------------------------------------------

        if {[dict get $result addNte]} {

            set nte \
                "NTE|1||Potassium above interface threshold"

            lappend outputSegments $nte
        }
    }


    return [join $outputSegments "\r"]
}


puts ""
puts "============================================================"
puts "TRANSFORM"
puts "============================================================"


set transformedMsg \
    [transform_oru $msg]


puts [string map {"\r" "\n"} $transformedMsg]


puts ""
puts "============================================================"
puts "VALIDATION"
puts "============================================================"


set potassiumFound 0


foreach segment [split $transformedMsg "\r"] {

    if {[hl7::segment_name $segment] ne "OBX"} {
        continue
    }


    set code \
        [hl7::get_from_segment $segment "OBX-3.1"]


    if {$code ne "K"} {
        continue
    }


    set potassiumFound 1


    set value \
        [hl7::get_from_segment $segment "OBX-5"]

    set flag \
        [hl7::get_from_segment $segment "OBX-8"]


    puts "Potassium value = $value"
    puts "Potassium flag  = $flag"


    if {$value > 5.5 && $flag eq "H"} {

        puts "PASS: Potassium transformation succeeded"

    } else {

        puts "FAIL: Potassium transformation incorrect"
    }
}


if {!$potassiumFound} {
    puts "FAIL: Potassium OBX not found"
}

set obx \
    "OBX|2|NM|K^Potassium||5.8|mmol/L|3.5-5.1|N|||F"

puts [hl7::get_from_segment $obx "OBX-3"]
puts [hl7::get_from_segment $obx "OBX-3.1"]
puts [hl7::get_from_segment $obx "OBX-3.2"]
puts [hl7::get_from_segment $obx "OBX-5"]

set obx \
    [hl7::set_in_segment $obx "OBX-8" "H"]

puts $obx


set transformation transform_oru

# set msg "ORU^R01 MESSAGE"

# $msg is the real multi-segment HL7 message.
set command \
    [list $transformation $msg]


puts ""
puts "============================================================"
puts "DYNAMIC COMMAND DEMO"
puts "============================================================"


puts "Number of elements in command:"
puts [llength $command]


puts ""
puts "Element 0 - procedure name:"
puts [lindex $command 0]


puts ""
puts "Element 1 - HL7 message:"
puts [string map {"\r" "\n"} \
    [lindex $command 1]]


puts ""
puts "Executing:"
puts "{*}\$command"


set result [{*}$command]


puts ""
puts "Result:"
puts [string map {"\r" "\n"} $result]
