# ============================================================
# LESSON 28
#
# SIU Scheduling Resource Groups
#
#   RGS
#      AIS  - Service
#      AIG  - General Resource
#      AIL  - Location Resource
#      AIP  - Personnel Resource
#
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
    "MSH|^~\\&|EPIC|TSH|SCHED|TSH|202610161100||SIU^S12|MSG28001|P|2.5" \
    "SCH|APT1001|FILL1001" \
    "PID|1||123456^^^TSH^MR||SMITH^JOHN||19800101|M" \
    "PV1|1|O|CARDCLINIC^101^1^TSH" \
    "RGS|1" \
    "AIS|1||CARD^Cardiology Follow-up" \
    "AIG|1||ECGCART01^ECG Cart|EQUIP^Equipment" \
    "AIP|1||1234^DOCTOR^JANE" \
    "AIL|1||CARDCLINIC^101^1^TSH" \
    "RGS|2" \
    "AIS|1||ECG^Electrocardiogram" \
    "AIG|1||ECGMACHINE02^ECG Machine|DEVICE^Device" \
    "AIP|1||5678^TECH^SAM" \
    "AIL|1||ECGLAB^201^1^TSH" \
] "\r"]

puts "============================================================"
puts "ORIGINAL SIU"
puts "============================================================"

puts [string map {"\r" "\n"} $msg]



proc build_siu_groups {msg} {

    set groups {}
    set currentGroup {}


    foreach segment [split $msg "\r"] {

        set segmentType \
            [hl7::segment_name $segment]


        switch -exact -- $segmentType {

            RGS {

                # Finish previous group.
                if {$currentGroup ne ""} {

                    lappend groups \
                        $currentGroup
                }


                # Start new group.
                set currentGroup \
                    [dict create \
                        rgs $segment \
                        services {} \
                        generalResources {} \
                        locations {} \
                        personnel {}]
            }


            AIS {

                if {$currentGroup ne ""} {

                    dict lappend \
                        currentGroup \
                        services \
                        $segment
                }
            }


            AIG {

                if {$currentGroup ne ""} {

                    dict lappend \
                        currentGroup \
                        generalResources \
                        $segment
                }
            }


            AIL {

                if {$currentGroup ne ""} {

                    dict lappend \
                        currentGroup \
                        locations \
                        $segment
                }
            }


            AIP {

                if {$currentGroup ne ""} {

                    dict lappend \
                        currentGroup \
                        personnel \
                        $segment
                }
            }
        }
    }


    # Final RGS group.
    if {$currentGroup ne ""} {

        lappend groups \
            $currentGroup
    }


    return $groups
}

set groups \
    [build_siu_groups $msg]


puts ""
puts "============================================================"
puts "SIU RESOURCE GROUPS"
puts "============================================================"


foreach group $groups {

    set rgs \
        [dict get $group rgs]


    set groupNumber \
        [hl7::get_from_segment \
            $rgs \
            "RGS-1"]


    puts ""
    puts "RGS $groupNumber"


    # --------------------------------------------------------
    # AIS - Service
    # --------------------------------------------------------

    foreach ais \
        [dict get $group services] {

        set code \
            [hl7::get_from_segment \
                $ais \
                "AIS-3.1"]

        set description \
            [hl7::get_from_segment \
                $ais \
                "AIS-3.2"]


        puts \
            "  AIS Service: $code - $description"
    }


    # --------------------------------------------------------
    # AIG - General Resource
    # --------------------------------------------------------

    foreach aig \
        [dict get $group generalResources] {

        set resourceId \
            [hl7::get_from_segment \
                $aig \
                "AIG-3.1"]

        set resourceName \
            [hl7::get_from_segment \
                $aig \
                "AIG-3.2"]

        set resourceType \
            [hl7::get_from_segment \
                $aig \
                "AIG-4.1"]


        puts \
            "  AIG Resource: $resourceId - $resourceName ($resourceType)"
    }


    # --------------------------------------------------------
    # AIP - Personnel
    # --------------------------------------------------------

    foreach aip \
        [dict get $group personnel] {

        set personId \
            [hl7::get_from_segment \
                $aip \
                "AIP-3.1"]

        set lastName \
            [hl7::get_from_segment \
                $aip \
                "AIP-3.2"]

        set firstName \
            [hl7::get_from_segment \
                $aip \
                "AIP-3.3"]


        puts \
            "  AIP Person: $personId - $firstName $lastName"
    }


    # --------------------------------------------------------
    # AIL - Location
    # --------------------------------------------------------

    foreach ail \
        [dict get $group locations] {

        set location \
            [hl7::get_from_segment \
                $ail \
                "AIL-3"]


        puts \
            "  AIL Location: $location"
    }
}


