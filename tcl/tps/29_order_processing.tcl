# ============================================================
# LESSON 29
#
# ORM / OML ORDER PROCESSING
#
# Main topics:
#
#   ORM^O01
#   ORC - Common Order
#   OBR - Observation Request
#
#   ORC-1  Order Control
#   ORC-2  Placer Order Number
#   ORC-3  Filler Order Number
#   ORC-5  Order Status
#
#   OBR-2  Placer Order Number
#   OBR-3  Filler Order Number
#   OBR-4  Universal Service Identifier
#
#   Multiple orders in one HL7 message
#   ORC -> OBR positional grouping
#   Context-aware transformations
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

# ============================================================
# TEST ORM MESSAGE
#
# Order 1:
#
#   ORC
#      OBR CBC
#
# Order 2:
#
#   ORC
#      OBR BMP
#      NTE
#
# ============================================================

set msg [join [list \
    "MSH|^~\\&|EPIC|TSH|LAB|TSH|202610161300||ORM^O01|MSG29001|P|2.5" \
    "PID|1||123456^^^TSH^MR||SMITH^JOHN||19800101|M" \
    "PV1|1|O|ER^01^01^TSH" \
    "ORC|NW|P1001^EPIC|F2001^LAB||SC" \
    "OBR|1|P1001^EPIC|F2001^LAB|CBC^Complete Blood Count" \
    "ORC|NW|P1002^EPIC|F2002^LAB||SC" \
    "OBR|1|P1002^EPIC|F2002^LAB|BMP^Basic Metabolic Panel" \
    "NTE|1||Patient fasting" \
] "\r"]


puts "============================================================"
puts "ORIGINAL ORDER MESSAGE"
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


proc describe_order_control {control} {

    switch -exact -- $control {

        NW {
            return "New order"
        }

        CA {
            return "Cancel order request"
        }

        DC {
            return "Discontinue order request"
        }

        XO {
            return "Change order request"
        }

        default {
            return "Other order control <$control>"
        }
    }
}

set orcSegments \
    [hl7::get_segments $msg ORC]


foreach orc $orcSegments {

    set control \
        [hl7::get_from_segment \
            $orc \
            "ORC-1"]

    puts ""
    puts "ORC-1 = $control"
    puts "Meaning = [describe_order_control $control]"
}



puts ""
puts "============================================================"
puts "2. ORDER IDENTIFIERS"
puts "============================================================"


foreach orc $orcSegments {

    set placerId \
        [hl7::get_from_segment \
            $orc \
            "ORC-2.1"]

    set placerNamespace \
        [hl7::get_from_segment \
            $orc \
            "ORC-2.2"]

    set fillerId \
        [hl7::get_from_segment \
            $orc \
            "ORC-3.1"]

    set fillerNamespace \
        [hl7::get_from_segment \
            $orc \
            "ORC-3.2"]


    puts ""
    puts "Placer = $placerId ($placerNamespace)"
    puts "Filler = $fillerId ($fillerNamespace)"
}

puts ""
puts "============================================================"
puts "3. ORDER GROUP TRAVERSAL"
puts "============================================================"


set currentOrc ""
set currentObr ""


foreach segment [split $msg "\r"] {

    set type \
        [hl7::segment_name $segment]


    switch -exact -- $type {

        ORC {

            set currentOrc $segment
            set currentObr ""


            set control \
                [hl7::get_from_segment \
                    $segment \
                    "ORC-1"]

            set placer \
                [hl7::get_from_segment \
                    $segment \
                    "ORC-2.1"]


            puts ""
            puts "ORDER:"
            puts "  Control = $control"
            puts "  Placer  = $placer"
        }


        OBR {

            if {$currentOrc eq ""} {

                puts "WARNING: OBR encountered without ORC"
                continue
            }


            set currentObr $segment


            set code \
                [hl7::get_from_segment \
                    $segment \
                    "OBR-4.1"]

            set description \
                [hl7::get_from_segment \
                    $segment \
                    "OBR-4.2"]


            puts "  Test    = $code - $description"
        }


        NTE {

            if {$currentObr ne ""} {

                set comment \
                    [hl7::get_from_segment \
                        $segment \
                        "NTE-3"]


                set testCode \
                    [hl7::get_from_segment \
                        $currentObr \
                        "OBR-4.1"]


                puts \
                    "      NTE for $testCode: $comment"
            }
        }
    }
}


proc build_order_groups {msg} {

    set groups {}

    set currentGroup {}


    foreach segment [split $msg "\r"] {

        set type \
            [hl7::segment_name $segment]


        switch -exact -- $type {

            ORC {

                # --------------------------------------------
                # Finish previous order.
                # --------------------------------------------

                if {$currentGroup ne ""} {

                    lappend groups \
                        $currentGroup
                }


                # --------------------------------------------
                # Start new order.
                # --------------------------------------------

                set currentGroup \
                    [dict create \
                        orc $segment \
                        obr "" \
                        ntes {}]
            }


            OBR {

                if {$currentGroup ne ""} {

                    dict set \
                        currentGroup \
                        obr \
                        $segment
                }
            }


            NTE {

                if {$currentGroup ne ""} {

                    dict lappend \
                        currentGroup \
                        ntes \
                        $segment
                }
            }
        }
    }


    # Final order group.
    if {$currentGroup ne ""} {

        lappend groups \
            $currentGroup
    }


    return $groups
}

set groups \
    [build_order_groups $msg]

puts ""
puts "============================================================"
puts "4. STRUCTURED ORDERS"
puts "============================================================"


set orderNumber 0


foreach group $groups {

    incr orderNumber


    set orc \
        [dict get $group orc]

    set obr \
        [dict get $group obr]


    set control \
        [hl7::get_from_segment \
            $orc \
            "ORC-1"]

    set status \
        [hl7::get_from_segment \
            $orc \
            "ORC-5"]

    set placerId \
        [hl7::get_from_segment \
            $orc \
            "ORC-2.1"]

    set fillerId \
        [hl7::get_from_segment \
            $orc \
            "ORC-3.1"]


    puts ""
    puts "ORDER $orderNumber"

    puts "  Control = $control"
    puts "  Status  = $status"
    puts "  Placer  = $placerId"
    puts "  Filler  = $fillerId"


    if {$obr ne ""} {

        set testCode \
            [hl7::get_from_segment \
                $obr \
                "OBR-4.1"]

        set testName \
            [hl7::get_from_segment \
                $obr \
                "OBR-4.2"]


        puts \
            "  Service = $testCode - $testName"
    }


    foreach nte \
        [dict get $group ntes] {


        set comment \
            [hl7::get_from_segment \
                $nte \
                "NTE-3"]


        puts "      NTE: $comment"
    }
}


proc map_order_code {sourceCode} {

    switch -exact -- $sourceCode {

        CBC {
            return "HEM-CBC"
        }

        BMP {
            return "CHEM-BMP"
        }

        default {
            return $sourceCode
        }
    }
}

proc transform_order_codes {msg} {

    set output {}


    foreach segment [split $msg "\r"] {

        set type \
            [hl7::segment_name $segment]


        if {$type eq "OBR"} {

            set sourceCode \
                [hl7::get_from_segment \
                    $segment \
                    "OBR-4.1"]


            set destinationCode \
                [map_order_code \
                    $sourceCode]


            if {$destinationCode ne $sourceCode} {

                set segment \
                    [hl7::set_in_segment \
                        $segment \
                        "OBR-4.1" \
                        $destinationCode]
            }
        }


        lappend output $segment
    }


    return [join $output "\r"]
}

set transformed \
    [transform_order_codes $msg]


puts ""
puts "============================================================"
puts "5. TRANSFORMED ORDER CODES"
puts "============================================================"

puts [string map {"\r" "\n"} $transformed]

proc cancel_second_order {msg} {

    set output {}

    set orderNumber 0


    foreach segment [split $msg "\r"] {

        set type \
            [hl7::segment_name $segment]


        if {$type eq "ORC"} {

            incr orderNumber


            if {$orderNumber == 2} {

                set segment \
                    [hl7::set_in_segment \
                        $segment \
                        "ORC-1" \
                        "CA"]
            }
        }


        lappend output $segment
    }


    return [join $output "\r"]
}


set cancellationMsg \
    [cancel_second_order $msg]

puts ""
puts "============================================================"
puts "6. SECOND ORDER CANCELLATION"
puts "============================================================"

puts [string map {"\r" "\n"} $cancellationMsg]


proc decide_order_action {orcSegment} {

    set control \
        [hl7::get_from_segment \
            $orcSegment \
            "ORC-1"]


    switch -exact -- $control {

        NW {

            return CREATE_ORDER
        }


        CA {

            return CANCEL_ORDER
        }


        DC {

            return DISCONTINUE_ORDER
        }


        XO {

            return MODIFY_ORDER
        }


        default {

            return REVIEW_ORDER
        }
    }
}

set cancellationGroups \
    [build_order_groups $cancellationMsg]


puts ""
puts "============================================================"
puts "7. ORDER ACTIONS"
puts "============================================================"


foreach group $cancellationGroups {

    set orc \
        [dict get $group orc]

    set placerId \
        [hl7::get_from_segment \
            $orc \
            "ORC-2.1"]


    set action \
        [decide_order_action \
            $orc]


    puts \
        "$placerId -> $action"
}

proc validate_order_identifiers {group} {

    set errors {}


    set orc \
        [dict get $group orc]

    set obr \
        [dict get $group obr]


    if {$obr eq ""} {

        lappend errors \
            "Order group has no OBR"

        return $errors
    }


    set orcPlacer \
        [hl7::get_from_segment \
            $orc \
            "ORC-2.1"]

    set obrPlacer \
        [hl7::get_from_segment \
            $obr \
            "OBR-2.1"]


    set orcFiller \
        [hl7::get_from_segment \
            $orc \
            "ORC-3.1"]

    set obrFiller \
        [hl7::get_from_segment \
            $obr \
            "OBR-3.1"]


    if {$orcPlacer ne $obrPlacer} {

        lappend errors \
            "ORC/OBR placer mismatch: \
ORC=$orcPlacer OBR=$obrPlacer"
    }


    if {$orcFiller ne $obrFiller} {

        lappend errors \
            "ORC/OBR filler mismatch: \
ORC=$orcFiller OBR=$obrFiller"
    }


    return $errors
}


puts ""
puts "============================================================"
puts "8. IDENTIFIER VALIDATION"
puts "============================================================"


foreach group $groups {

    set errors \
        [validate_order_identifiers \
            $group]


    if {[llength $errors] == 0} {

        puts "Order identifiers: PASS"

    } else {

        puts "Order identifiers: REVIEW"

        foreach err $errors {

            puts "  $err"
        }
    }
}



