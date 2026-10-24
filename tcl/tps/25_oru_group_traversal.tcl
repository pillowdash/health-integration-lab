# ============================================================
# LESSON 25
#
# Production-style ORU traversal
#
# Topics:
#
#   OBR -> OBX -> NTE relationships
#   OBR-level NTE
#   OBX-level NTE
#   Stateful traversal
#   Grouping with dict/list
#   Repeating fields
#   Context-aware transformation
#   Preserve original segment order
#   Simple structural validation
#
# NOTE:
# This is a simplified ORU learning model.
# It is not intended to implement the entire formal ORU_R01
# grammar for every HL7 version/profile.
# ============================================================


# ============================================================
# LOAD OUR HL7 LIBRARY
# ============================================================

set scriptDir \
    [file dirname [file normalize [info script]]]

set tclRoot \
    [file normalize [file join $scriptDir ..]]

set libDir \
    [file join $tclRoot lib]

lappend auto_path $libDir


package require hl7utils


# ============================================================
# TEST ORU MESSAGE
#
# Structure:
#
#   OBR CBC
#       OBX WBC
#           NTE
#       OBX HGB
#
#   OBR BMP
#       NTE                  <-- OBR-level NTE
#       OBX Sodium
#       OBX Potassium
#           NTE              <-- OBX-level NTE
#       OBX Comment
#
# ============================================================

set msg [join [list \
    "MSH|^~\\&|EPIC|TSH|LAB|TSH|202610101400||ORU^R01|MSG25001|P|2.5" \
    "PID|1||123456^^^TSH^MR||SMITH^JOHN" \
    "OBR|1|ORD1001|LAB1001|CBC^Complete Blood Count" \
    "OBX|1|NM|WBC^White Blood Cells||7.4|10*9/L|4.0-11.0|N|||F" \
    "NTE|1||Automated differential performed" \
    "OBX|2|NM|HGB^Hemoglobin||145|g/L|120-160|N|||F" \
    "OBR|2|ORD1002|LAB1002|BMP^Basic Metabolic Panel" \
    "NTE|1||BMP panel processed at TSH laboratory" \
    "OBX|1|NM|NA^Sodium||140|mmol/L|135-145|N|||F" \
    "OBX|2|NM|K^Potassium||5.8|mmol/L|3.5-5.1|N|||F" \
    "NTE|1||Result verified by laboratory" \
    "OBX|3|TX|COMMENT^Result Comment||First line~Second line|||N|||F" \
] "\r"]


puts "============================================================"
puts "ORIGINAL ORU"
puts "============================================================"

puts [string map {"\r" "\n"} $msg]


# ============================================================
# 1. SIMPLE SEQUENTIAL TRAVERSAL
# ============================================================

puts ""
puts "============================================================"
puts "1. SEQUENTIAL TRAVERSAL"
puts "============================================================"


foreach segment [split $msg "\r"] {

    set segmentType \
        [hl7::segment_name $segment]

    puts "Segment type = $segmentType"
}


# ============================================================
# 2. STATEFUL OBR / OBX / NTE TRAVERSAL
#
# We remember:
#
#   currentObr
#   currentObx
#
# If NTE appears:
#
#   currentObx exists
#       -> treat as OBX-level NTE
#
#   currentObx empty but currentObr exists
#       -> treat as OBR-level NTE
#
# ============================================================

puts ""
puts "============================================================"
puts "2. OBR / OBX / NTE CONTEXT"
puts "============================================================"


set currentObr ""
set currentObx ""


foreach segment [split $msg "\r"] {

    set segmentType \
        [hl7::segment_name $segment]


    switch -exact -- $segmentType {

        OBR {

            set currentObr $segment

            # New OBR means there is no current OBX yet.
            set currentObx ""


            set panelCode \
                [hl7::get_from_segment \
                    $segment \
                    "OBR-4.1"]

            set panelName \
                [hl7::get_from_segment \
                    $segment \
                    "OBR-4.2"]


            puts ""
            puts "PANEL: $panelCode - $panelName"
        }


        OBX {

            set currentObx $segment


            set code \
                [hl7::get_from_segment \
                    $segment \
                    "OBX-3.1"]

            set name \
                [hl7::get_from_segment \
                    $segment \
                    "OBX-3.2"]

            set value \
                [hl7::get_from_segment \
                    $segment \
                    "OBX-5"]


            puts "  RESULT: $code - $name = $value"
        }


        NTE {

            set comment \
                [hl7::get_from_segment \
                    $segment \
                    "NTE-3"]


            if {$currentObx ne ""} {

                # --------------------------------------------
                # OBX-level NTE
                # --------------------------------------------

                set obxCode \
                    [hl7::get_from_segment \
                        $currentObx \
                        "OBX-3.1"]

                puts \
                    "      OBX NTE for $obxCode: $comment"

            } elseif {$currentObr ne ""} {

                # --------------------------------------------
                # OBR-level NTE
                # --------------------------------------------

                set panelCode \
                    [hl7::get_from_segment \
                        $currentObr \
                        "OBR-4.1"]

                puts \
                    "    OBR NTE for $panelCode: $comment"

            } else {

                puts \
                    "WARNING: NTE encountered without OBR/OBX context"
            }
        }
    }
}


# ============================================================
# 3. BUILD STRUCTURED OBR GROUPS
#
# Structure:
#
# groups
#   |
#   +-- group
#       |
#       +-- obr
#       |
#       +-- ntes
#       |     OBR-level NTEs
#       |
#       +-- observations
#             |
#             +-- observation
#                   |
#                   +-- obx
#                   |
#                   +-- ntes
#                         OBX-level NTEs
#
# ============================================================

proc build_oru_groups {msg} {

    set groups {}

    set currentGroup {}
    set currentObservation {}


    foreach segment [split $msg "\r"] {

        set segmentType \
            [hl7::segment_name $segment]


        switch -exact -- $segmentType {

            OBR {

                # --------------------------------------------
                # Finish previous OBX observation.
                # --------------------------------------------

                if {$currentObservation ne ""} {

                    dict lappend \
                        currentGroup \
                        observations \
                        $currentObservation

                    set currentObservation {}
                }


                # --------------------------------------------
                # Finish previous OBR group.
                # --------------------------------------------

                if {$currentGroup ne ""} {

                    lappend groups \
                        $currentGroup
                }


                # --------------------------------------------
                # Start a new OBR group.
                # --------------------------------------------

                set currentGroup \
                    [dict create \
                        obr $segment \
                        ntes {} \
                        observations {}]
            }


            OBX {

                # --------------------------------------------
                # Finish previous OBX observation.
                # --------------------------------------------

                if {$currentObservation ne ""} {

                    dict lappend \
                        currentGroup \
                        observations \
                        $currentObservation
                }


                # --------------------------------------------
                # Start new OBX observation.
                # --------------------------------------------

                set currentObservation \
                    [dict create \
                        obx $segment \
                        ntes {}]
            }


            NTE {

                if {$currentObservation ne ""} {

                    # ----------------------------------------
                    # NTE after an OBX:
                    # attach to current observation.
                    # ----------------------------------------

                    dict lappend \
                        currentObservation \
                        ntes \
                        $segment

                } elseif {$currentGroup ne ""} {

                    # ----------------------------------------
                    # NTE after OBR but before first OBX:
                    # attach to OBR group.
                    # ----------------------------------------

                    dict lappend \
                        currentGroup \
                        ntes \
                        $segment
                }
            }
        }
    }


    # ========================================================
    # FINAL FLUSH
    #
    # There is no "next OBX" or "next OBR" after the last
    # group, so explicitly store the final objects here.
    # ========================================================

    if {$currentObservation ne ""} {

        dict lappend \
            currentGroup \
            observations \
            $currentObservation
    }


    if {$currentGroup ne ""} {

        lappend groups \
            $currentGroup
    }


    return $groups
}


# ============================================================
# 4. DISPLAY STRUCTURED GROUPS
# ============================================================

puts ""
puts "============================================================"
puts "3. STRUCTURED OBR GROUPS"
puts "============================================================"


set groups \
    [build_oru_groups $msg]


set groupNumber 0


foreach group $groups {

    incr groupNumber


    set obr \
        [dict get $group obr]


    set panelCode \
        [hl7::get_from_segment \
            $obr \
            "OBR-4.1"]

    set panelName \
        [hl7::get_from_segment \
            $obr \
            "OBR-4.2"]


    puts ""
    puts "GROUP $groupNumber"
    puts "Panel = $panelCode - $panelName"


    # --------------------------------------------------------
    # OBR-level NTEs
    # --------------------------------------------------------

    foreach nte [dict get $group ntes] {

        set comment \
            [hl7::get_from_segment \
                $nte \
                "NTE-3"]


        puts "  OBR NTE: $comment"
    }


    # --------------------------------------------------------
    # OBX observations
    # --------------------------------------------------------

    foreach observation \
        [dict get $group observations] {


        set obx \
            [dict get $observation obx]


        set code \
            [hl7::get_from_segment \
                $obx \
                "OBX-3.1"]

        set name \
            [hl7::get_from_segment \
                $obx \
                "OBX-3.2"]

        set value \
            [hl7::get_from_segment \
                $obx \
                "OBX-5"]


        puts "  $code - $name = $value"


        # ----------------------------------------------------
        # OBX-5 repetitions
        # ----------------------------------------------------

        set repetitions \
            [split $value "~"]


        if {[llength $repetitions] > 1} {

            foreach repetition $repetitions {

                puts \
                    "      Repetition = <$repetition>"
            }
        }


        # ----------------------------------------------------
        # OBX-level NTEs
        # ----------------------------------------------------

        foreach nte \
            [dict get $observation ntes] {

            set comment \
                [hl7::get_from_segment \
                    $nte \
                    "NTE-3"]


            puts "      NTE: $comment"
        }
    }
}


# ============================================================
# 5. TRANSFORM VERSION 1
#
# OBX-only context.
#
# Rule:
#
#   OBX-3.1 = K
#   AND
#   OBX-5 > threshold
#
#       -> OBX-8 = H
#
# This preserves original segment order.
# ============================================================

proc transform_oru_preserve_structure {
    msg
    threshold
} {

    if {![string is double -strict $threshold]} {

        error "Invalid threshold <$threshold>"
    }


    set output {}


    foreach segment [split $msg "\r"] {

        set segmentType \
            [hl7::segment_name $segment]


        if {$segmentType eq "OBX"} {

            set code \
                [hl7::get_from_segment \
                    $segment \
                    "OBX-3.1"]


            set value \
                [hl7::get_from_segment \
                    $segment \
                    "OBX-5"]


            if {$code eq "K" &&
                [string is double -strict $value] &&
                $value > $threshold} {

                set segment \
                    [hl7::set_in_segment \
                        $segment \
                        "OBX-8" \
                        "H"]
            }
        }


        lappend output $segment
    }


    return [join $output "\r"]
}


puts ""
puts "============================================================"
puts "4. TRANSFORM VERSION 1 - OBX ONLY"
puts "============================================================"


set transformed \
    [transform_oru_preserve_structure \
        $msg \
        5.5]


puts [string map {"\r" "\n"} $transformed]


# ============================================================
# 6. TRANSFORM VERSION 2
#
# Context-aware transformation.
#
# Rule:
#
#   current OBR-4.1 = BMP
#   AND
#   OBX-3.1 = K
#   AND
#   OBX-5 > threshold
#
#       -> OBX-8 = H
#
# This is the preferred transformation example for this lesson.
# ============================================================

proc transform_bmp_potassium {
    msg
    threshold
} {

    if {![string is double -strict $threshold]} {

        error "Invalid threshold <$threshold>"
    }


    set output {}

    set currentPanel ""


    foreach segment [split $msg "\r"] {

        set segmentType \
            [hl7::segment_name $segment]


        switch -exact -- $segmentType {

            OBR {

                set currentPanel \
                    [hl7::get_from_segment \
                        $segment \
                        "OBR-4.1"]
            }


            OBX {

                set code \
                    [hl7::get_from_segment \
                        $segment \
                        "OBX-3.1"]


                set value \
                    [hl7::get_from_segment \
                        $segment \
                        "OBX-5"]


                if {$currentPanel eq "BMP" &&
                    $code eq "K" &&
                    [string is double -strict $value] &&
                    $value > $threshold} {

                    set segment \
                        [hl7::set_in_segment \
                            $segment \
                            "OBX-8" \
                            "H"]
                }
            }
        }


        # ----------------------------------------------------
        # Preserve every segment in its original position.
        # ----------------------------------------------------

        lappend output $segment
    }


    return [join $output "\r"]
}


puts ""
puts "============================================================"
puts "5. TRANSFORM VERSION 2 - BMP + POTASSIUM"
puts "============================================================"


set transformedBmp \
    [transform_bmp_potassium \
        $msg \
        5.5]


puts [string map {"\r" "\n"} $transformedBmp]


# ============================================================
# 7. SIMPLE STRUCTURAL VALIDATION
#
# For our lesson/profile:
#
#   OBX should occur under an OBR.
#
#   NTE is allowed:
#
#       after OBR before first OBX
#           -> OBR-level NTE
#
#       after OBX
#           -> OBX-level NTE
#
# This is NOT a complete ORU conformance validator.
# ============================================================

proc validate_oru_structure {msg} {

    set errors {}

    set currentObr ""
    set currentObx ""


    foreach segment [split $msg "\r"] {

        set segmentType \
            [hl7::segment_name $segment]


        switch -exact -- $segmentType {

            OBR {

                set currentObr $segment
                set currentObx ""
            }


            OBX {

                if {$currentObr eq ""} {

                    lappend errors \
                        "OBX found before any OBR"
                }


                set currentObx $segment
            }


            NTE {

                if {$currentObr eq ""} {

                    lappend errors \
                        "NTE found before any OBR context"
                }
            }
        }
    }


    return $errors
}


puts ""
puts "============================================================"
puts "6. STRUCTURE VALIDATION"
puts "============================================================"


set errors \
    [validate_oru_structure $msg]


if {[llength $errors] == 0} {

    puts "Structure validation: PASS"

} else {

    puts "Structure validation: FAIL"

    foreach err $errors {

        puts "  $err"
    }
}


# ============================================================
# 8. FINAL CHECK
#
# Confirm potassium changed only in the transformed message.
# ============================================================

puts ""
puts "============================================================"
puts "7. FINAL POTASSIUM CHECK"
puts "============================================================"


foreach segment [split $transformedBmp "\r"] {

    if {[hl7::segment_name $segment] ne "OBX"} {
        continue
    }


    set code \
        [hl7::get_from_segment \
            $segment \
            "OBX-3.1"]


    if {$code ne "K"} {
        continue
    }


    set value \
        [hl7::get_from_segment \
            $segment \
            "OBX-5"]

    set flag \
        [hl7::get_from_segment \
            $segment \
            "OBX-8"]


    puts "Potassium value = $value"
    puts "Potassium flag  = $flag"


    if {$value > 5.5 && $flag eq "H"} {

        puts "PASS: BMP potassium transformation succeeded"

    } else {

        puts "FAIL: BMP potassium transformation did not succeed"
    }
}
