# ============================================================
# Lab 28
#
# SIU Scheduling Messages
#
# Topics:
#
#   SIU^S12 / S13 / S14 / S15 / S26
#   SCH appointment identifiers
#   PID / PV1 context
#   RGS resource groups
#   AIS service resources
#   AIP personnel resources
#   AIL location resources
#   Stateful traversal
#   Building structured SIU groups
#   Trigger-based routing
#
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
# TEST SIU MESSAGE
#
# Simplified structure:
#
#   MSH
#   SCH
#   PID
#   PV1
#
#   RGS 1
#       AIS - Cardiology follow-up
#       AIP - Dr. Jane Doctor
#       AIL - Cardiology clinic
#
#   RGS 2
#       AIS - ECG
#       AIP - Sam Tech
#       AIL - ECG Lab
#
# ============================================================

set msg [join [list \
    "MSH|^~\\&|EPIC|TSH|SCHEDULING|TSH|202610111700||SIU^S12|MSG27001|P|2.5" \
    "SCH|APT1001|FILL1001" \
    "PID|1||123456^^^TSH^MR~998877^^^OHIP^JHN||SMITH^JOHN||19800101|M" \
    "PV1|1|O|CARDCLINIC^101^1^TSH" \
    "RGS|1" \
    "AIS|1||CARD^Cardiology Follow-up" \
    "AIP|1||1234^DOCTOR^JANE" \
    "AIL|1||CARDCLINIC^101^1^TSH" \
    "RGS|2" \
    "AIS|1||ECG^Electrocardiogram" \
    "AIP|1||5678^TECH^SAM" \
    "AIL|1||ECGLAB^201^1^TSH" \
] "\r"]


puts "============================================================"
puts "ORIGINAL SIU MESSAGE"
puts "============================================================"

puts [string map {"\r" "\n"} $msg]


# ============================================================
# 1. IDENTIFY MESSAGE TYPE
# ============================================================

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

# ============================================================
# 2. SIU TRIGGER CLASSIFICATION
# ============================================================

proc describe_siu_trigger {trigger} {

    switch -exact -- $trigger {

        S12 {
            return "New appointment booking"
        }

        S13 {
            return "Appointment rescheduling"
        }

        S14 {
            return "Appointment modification"
        }

        S15 {
            return "Appointment cancellation"
        }

        S26 {
            return "Patient did not show"
        }

        default {
            return "Other / unsupported SIU event"
        }
    }
}


puts ""
puts "Trigger meaning:"
puts [describe_siu_trigger $triggerEvent]

proc is_supported_siu {msg} {

    set typeInfo \
        [hl7::get_message_type_components $msg]


    set messageCode \
        [dict get $typeInfo messageCode]

    set triggerEvent \
        [dict get $typeInfo triggerEvent]


    if {$messageCode ne "SIU"} {
        return 0
    }


    switch -exact -- $triggerEvent {

        S12 -
        S13 -
        S14 -
        S15 -
        S26 {

            return 1
        }


        default {

            return 0
        }
    }
}

puts ""
puts "============================================================"
puts "2. SCH APPOINTMENT IDENTIFIERS"
puts "============================================================"


set placerAppointmentId \
    [hl7::get $msg "SCH-1"]

set fillerAppointmentId \
    [hl7::get $msg "SCH-2"]


puts "SCH-1 Placer appointment ID = $placerAppointmentId"
puts "SCH-2 Filler appointment ID = $fillerAppointmentId"

puts ""
puts "============================================================"
puts "3. PATIENT / ENCOUNTER CONTEXT"
puts "============================================================"


set pid3 \
    [hl7::get $msg "PID-3"]

set patientClass \
    [hl7::get $msg "PV1-2"]

set patientLocation \
    [hl7::get $msg "PV1-3"]


puts "PID-3 = $pid3"
puts "PV1-2 = $patientClass"
puts "PV1-3 = $patientLocation"

puts ""
puts "============================================================"
puts "4. SEQUENTIAL TRAVERSAL"
puts "============================================================"


foreach segment [split $msg "\r"] {

    set type \
        [hl7::segment_name $segment]

    puts "Segment type = $type"
}

puts ""
puts "============================================================"
puts "5. RESOURCE GROUP CONTEXT"
puts "============================================================"


set currentRgs ""


foreach segment [split $msg "\r"] {

    set type \
        [hl7::segment_name $segment]


    switch -exact -- $type {

        RGS {

            set currentRgs $segment


            set groupNumber \
                [hl7::get_from_segment \
                    $segment \
                    "RGS-1"]


            puts ""
            puts "RESOURCE GROUP $groupNumber"
        }


        AIS {

            if {$currentRgs eq ""} {

                puts "WARNING: AIS without RGS"
                continue
            }


            set serviceCode \
                [hl7::get_from_segment \
                    $segment \
                    "AIS-3.1"]

            set serviceName \
                [hl7::get_from_segment \
                    $segment \
                    "AIS-3.2"]


            puts \
                "  SERVICE: $serviceCode - $serviceName"
        }


        AIP {

            if {$currentRgs eq ""} {

                puts "WARNING: AIP without RGS"
                continue
            }


            set personnelId \
                [hl7::get_from_segment \
                    $segment \
                    "AIP-3.1"]

            set personnelLastName \
                [hl7::get_from_segment \
                    $segment \
                    "AIP-3.2"]

            set personnelFirstName \
                [hl7::get_from_segment \
                    $segment \
                    "AIP-3.3"]


            puts \
                "  PERSON: $personnelId - \
$personnelFirstName $personnelLastName"
        }


        AIL {

            if {$currentRgs eq ""} {

                puts "WARNING: AIL without RGS"
                continue
            }


            set location \
                [hl7::get_from_segment \
                    $segment \
                    "AIL-3"]


            puts "  LOCATION: $location"
        }
    }
}

proc build_siu_groups {msg} {

    set groups {}

    set currentGroup {}


    foreach segment [split $msg "\r"] {

        set type \
            [hl7::segment_name $segment]


        switch -exact -- $type {

            RGS {

                # --------------------------------------------
                # Finish previous resource group.
                # --------------------------------------------

                if {$currentGroup ne ""} {

                    lappend groups \
                        $currentGroup
                }


                # --------------------------------------------
                # Start new resource group.
                # --------------------------------------------

                set currentGroup \
                    [dict create \
                        rgs $segment \
                        services {} \
                        personnel {} \
                        locations {}]
            }


            AIS {

                if {$currentGroup ne ""} {

                    dict lappend \
                        currentGroup \
                        services \
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


            AIL {

                if {$currentGroup ne ""} {

                    dict lappend \
                        currentGroup \
                        locations \
                        $segment
                }
            }
        }
    }


    # --------------------------------------------------------
    # Final group must be flushed after the loop.
    # --------------------------------------------------------

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
puts "6. STRUCTURED RESOURCE GROUPS"
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
    # Services
    # --------------------------------------------------------

    foreach ais [dict get $group services] {

        set code \
            [hl7::get_from_segment \
                $ais \
                "AIS-3.1"]

        set name \
            [hl7::get_from_segment \
                $ais \
                "AIS-3.2"]


        puts "  SERVICE: $code - $name"
    }


    # --------------------------------------------------------
    # Personnel
    # --------------------------------------------------------

    foreach aip [dict get $group personnel] {

        set id \
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
            "  PERSON: $id - $firstName $lastName"
    }


    # --------------------------------------------------------
    # Locations
    # --------------------------------------------------------

    foreach ail [dict get $group locations] {

        set location \
            [hl7::get_from_segment \
                $ail \
                "AIL-3"]


        puts "  LOCATION: $location"
    }
}

set noShowMsg \
    [hl7::set_field \
        $msg \
        "MSH-9.2" \
        "S26"]


puts ""
puts "============================================================"
puts "7. SIMULATED SIU^S26"
puts "============================================================"


puts [string map {"\r" "\n"} $noShowMsg]


set noShowType \
    [hl7::get_message_type_components \
        $noShowMsg]


puts ""
puts "Message = \
[dict get $noShowType messageCode]^\
[dict get $noShowType triggerEvent]"


puts "Meaning = \
[describe_siu_trigger \
    [dict get $noShowType triggerEvent]]"


proc process_siu {msg} {

    set typeInfo \
        [hl7::get_message_type_components $msg]


    set messageCode \
        [dict get $typeInfo messageCode]

    set trigger \
        [dict get $typeInfo triggerEvent]


    if {$messageCode ne "SIU"} {

        return [dict create \
            disposition CONTINUE \
            message $msg \
            action NONE \
            reason "Not an SIU message"]
    }


    switch -exact -- $trigger {

        S12 {

            set action CREATE_APPOINTMENT
        }


        S13 {

            set action RESCHEDULE_APPOINTMENT
        }


        S14 {

            set action MODIFY_APPOINTMENT
        }


        S15 {

            set action CANCEL_APPOINTMENT
        }


        S26 {

            set action MARK_NO_SHOW
        }


        default {

            return [dict create \
                disposition CONTINUE \
                message $msg \
                action NONE \
                reason "Unsupported SIU trigger <$trigger>"]
        }
    }


    return [dict create \
        disposition CONTINUE \
        message $msg \
        action $action \
        reason \
            [describe_siu_trigger $trigger]]
}


set result \
    [process_siu $msg]


puts ""
puts "S12 action:"
puts [dict get $result action]

puts "Reason:"
puts [dict get $result reason]

set result \
    [process_siu $noShowMsg]


puts ""
puts "S26 action:"
puts [dict get $result action]

puts "Reason:"
puts [dict get $result reason]

proc summarize_siu {msg} {

    set typeInfo \
        [hl7::get_message_type_components $msg]


    set trigger \
        [dict get $typeInfo triggerEvent]


    set placerAppointmentId \
        [hl7::get $msg "SCH-1"]

    set fillerAppointmentId \
        [hl7::get $msg "SCH-2"]

    set pid3 \
        [hl7::get $msg "PID-3"]

    set patientClass \
        [hl7::get $msg "PV1-2"]

    set location \
        [hl7::get $msg "PV1-3"]

    set groups \
        [build_siu_groups $msg]


    return [dict create \
        trigger $trigger \
        triggerMeaning \
            [describe_siu_trigger $trigger] \
        placerAppointmentId \
            $placerAppointmentId \
        fillerAppointmentId \
            $fillerAppointmentId \
        pid3 $pid3 \
        patientClass $patientClass \
        location $location \
        resourceGroups $groups]
}

set summary \
    [summarize_siu $noShowMsg]


puts ""
puts "============================================================"
puts "8. SIU SUMMARY"
puts "============================================================"


puts "Trigger:"
puts [dict get $summary trigger]

puts ""

puts "Meaning:"
puts [dict get $summary triggerMeaning]

puts ""

puts "Placer appointment ID:"
puts [dict get $summary placerAppointmentId]

puts ""

puts "Filler appointment ID:"
puts [dict get $summary fillerAppointmentId]

puts ""

puts "Patient class:"
puts [dict get $summary patientClass]

puts ""

puts "Location:"
puts [dict get $summary location]

puts ""

puts "Number of resource groups:"
puts [llength [dict get $summary resourceGroups]]





