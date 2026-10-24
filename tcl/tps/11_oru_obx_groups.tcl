lappend auto_path [file normalize "tcl/lib"]

package require hl7utils


# ----------------------------------------------------------
# Extract all OBR groups and their OBX segments
# ----------------------------------------------------------
proc get_obr_groups {msg} {

    set segments [split $msg "\r"]

    set groups {}


    #  the “state while looping” idea in action.
    # The state is mainly stored in this variable:
    # currentGroup

    # As the loop moves through each HL7 segment, currentGroup remembers:
    # “Which OBR group am I currently building?”
    set currentGroup ""

    foreach segment $segments {

        set fields [split $segment "|"]
        set segmentName [lindex $fields 0]

        switch -exact -- $segmentName {

            OBR {
                # If we already had an OBR group,
                # save it before starting the next one.
                # save that finished group into groups : save previous group here
                if {$currentGroup ne ""} {
                    lappend groups $currentGroup
                }

                # Start a brand-new group for the new OBR that just arrived
                set currentGroup [dict create \
                    obr $segment \
                    obxSegments {}]
            }

            OBX {
                # Only attach OBX if we have already seen an OBR
                if {$currentGroup ne ""} {

                    set obxList [dict get $currentGroup obxSegments]

                    lappend obxList $segment

                    dict set currentGroup obxSegments $obxList
                }
            }
        }
    }

    # Save the final group
    if {$currentGroup ne ""} {
        lappend groups $currentGroup
    }

    return $groups
}


# ----------------------------------------------------------
# Process one OBR
# ----------------------------------------------------------
proc process_obr_group {group} {

    set obr [dict get $group obr]
    set obxSegments [dict get $group obxSegments]

    set obrFields [split $obr "|"]

    # Simplified lab extraction
    set fillerOrderNumber [lindex $obrFields 3]
    set service          [lindex $obrFields 4]

    puts ""
    puts "--------------------------------------------"
    puts "OBR"
    puts "--------------------------------------------"
    puts "Filler Order Number = $fillerOrderNumber"
    puts "Service             = $service"
    puts "OBX Count           = [llength $obxSegments]"

    foreach obx $obxSegments {

        set fields [split $obx "|"]

        set setId        [lindex $fields 1]
        set valueType    [lindex $fields 2]
        set observation  [lindex $fields 3]
        set value        [lindex $fields 5]
        set units        [lindex $fields 6]
        set reference    [lindex $fields 7]
        set abnormalFlag [lindex $fields 8]
        set resultStatus [lindex $fields 11]

        puts ""
        puts "  OBX-$setId"
        puts "    Value Type    = $valueType"
        puts "    Observation   = $observation"
        puts "    Value         = $value"
        puts "    Units         = $units"
        puts "    Reference     = $reference"
        puts "    Abnormal Flag = $abnormalFlag"
        puts "    Status        = $resultStatus"
    }
}


# ----------------------------------------------------------
# Test ORU^R01 message
# ----------------------------------------------------------

set msg "MSH|^~\\&|LABSYS|TSH|EPIC|TSH|202610031000||ORU^R01^ORU_R01|ORU000501|P|2.5\rPID|1||123456^^^TSH^MR||SMITH^JOHN||19800101|M\rOBR|1|ORD1001|LAB1001|CBC^Complete Blood Count|||202610030900\rOBX|1|NM|WBC^White Blood Cells||7.4|10^9/L|4.0-11.0|N|||F\rOBX|2|NM|HGB^Hemoglobin||145|g/L|135-175|N|||F\rOBX|3|NM|PLT^Platelets||250|10^9/L|150-400|N|||F\rOBR|2|ORD1002|LAB1002|BMP^Basic Metabolic Panel|||202610030905\rOBX|1|NM|NA^Sodium||140|mmol/L|135-145|N|||F\rOBX|2|NM|K^Potassium||5.8|mmol/L|3.5-5.1|H|||F"


# ----------------------------------------------------------
# Identify message type
# ----------------------------------------------------------

set typeInfo [hl7::get_message_type_components $msg]

set messageCode  [dict get $typeInfo messageCode]
set triggerEvent [dict get $typeInfo triggerEvent]

puts "Message Code   = $messageCode"
puts "Trigger Event  = $triggerEvent"
puts "Control ID     = [hl7::get_message_control_id $msg]"


# ----------------------------------------------------------
# Dispatch based on message type
# ----------------------------------------------------------

switch -exact -- $messageCode {

    ORU {

        puts ""
        puts "Processing ORU message..."

        set groups [get_obr_groups $msg]

        puts "Number of OBR groups = [llength $groups]"

        foreach group $groups {
            process_obr_group $group
        }
    }

    default {
        puts "Unsupported message type: $messageCode"
    }
}


set obxSegments [hl7::get_segments $msg "OBX"]

puts "OBX count = [llength $obxSegments]"

set firstObx  [hl7::get_segment_n $msg OBX 1]
set secondObx [hl7::get_segment_n $msg OBX 2]
set otherObx [hl7::get_segment_n $msg OBX 5]


puts "OBX 1 = $firstObx"
puts "OBX 2 = $secondObx"
puts "OBX 5 = $otherObx"
