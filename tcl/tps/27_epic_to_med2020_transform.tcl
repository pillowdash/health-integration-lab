# ============================================================
# Lab 27
#
# Real-world style transformation:
#
#     Epic ADT
#         |
#         v
#     Integration Engine Mapper
#         |
#         v
#     Med2020-style ADT
#
#
# Main concepts:
#
#   1. Segment filtering
#   2. Field projection
#   3. Identifier selection
#   4. Datatype/component manipulation
#   5. Message-profile conversion
#   6. Destination-specific segment generation
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
# Create an empty HL7 segment represented as a Tcl list.
#
# Example:
#
#   set pid [new_segment PID 18]
#
# creates:
#
#   PID||||||||||||||||||
#
# internally as a Tcl list.
# ============================================================

proc new_segment {segmentName maxField} {

    set fields \
        [lrepeat \
            [expr {$maxField + 1}] \
            ""]

    lset fields 0 $segmentName

    return $fields
}


# ============================================================
# SOURCE PID
# ============================================================

set pidFields \
    [new_segment PID 18]


lset pidFields 1 \
    "1"


# Multiple identifiers, similar to the real Epic concept:
#
#   EPI MR
#   MT MR
#
lset pidFields 3 \
    "E123456^^^EPI^MR~M000880^^^MT^MR"


lset pidFields 5 \
    "TESTPATIENT^JANE"


lset pidFields 7 \
    "19840104"


lset pidFields 8 \
    "F"


lset pidFields 11 \
    "1001 SAMPLE RD^^BURLINGTON^ON^L7R1H4^CA"


lset pidFields 13 \
    "(905)555-1554^PRN^PH^^1^905^5551554"


lset pidFields 15 \
    "E"


lset pidFields 18 \
    "ACCT001"


set pidSegment \
    [join $pidFields "|"]


# ============================================================
# SOURCE PV1
# ============================================================

set pv1Fields \
    [new_segment PV1 50]


lset pv1Fields 1 \
    "1"


# Source patient-class representation.
lset pv1Fields 2 \
    "I/P"


# Rich Epic location.
lset pv1Fields 3 \
    "7S100^7S100HW^02^TSH20001"


lset pv1Fields 4 \
    "E"


# Attending/provider represented as XCN-like data.
lset pv1Fields 7 \
    "1000^FAMILY MEDICINE^PHYSICIAN"


lset pv1Fields 14 \
    "E"


lset pv1Fields 17 \
    "1000^FAMILY MEDICINE^PHYSICIAN"


lset pv1Fields 19 \
    "503811"


lset pv1Fields 20 \
    "01"


lset pv1Fields 21 \
    "200330256"


lset pv1Fields 42 \
    "1160"


lset pv1Fields 44 \
    "20260925112800"


lset pv1Fields 50 \
    "101000117526^^^^IP"


set pv1Segment \
    [join $pv1Fields "|"]


# ============================================================
# SOURCE EPIC MESSAGE
#
# Several segments exist only to demonstrate that the
# destination mapper deliberately suppresses them.
# ============================================================

set sourceMsg [join [list \
    "MSH|^~\\&|EPIC|TSH|RHAPSODY|PRIMARY|20261013110953|30071|ADT^A08^ADT_A01|334720.110796|T|2.4|||||||Security_Restrictions-Epic-1.0" \
    "EVN|A08|20261013110953||REG_VIS_CHANGE|30071^TSH INPATIENT^NURSE" \
    $pidSegment \
    "ZPD|MYCH|NSTD MYC STAT" \
    "PD1|||SAMPLE HOSPITAL||||||||SAMPLE PROVIDER" \
    "ROL|1|UP|GENERAL|1000^FAMILY MEDICINE^PHYSICIAN" \
    "ROL|2|UP|Gastro|1024^SPECIALIST^DOCTOR" \
    $pv1Segment \
    "PV2|1|Ward|||||20260925" \
    "ZPV||||||||20260925112800" \
    "ROL|3|UP|RN|10656149^INPATIENT^NURSE" \
    "OBX|1|TX|CC^Complex Care^CHIPATCLASS||1161^CHI COMP CA||||||F" \
    "OBX|2|TX|DS^Day Surgery^CHIPATCLASS||4144^CHI OP||||||F" \
    "OBX|3|TX|ED^Emergency^CHIPATCLASS||4144^CHI OP||||||F" \
    "IN1|1|23501^SAMPLE INSURANCE PLAN" \
] "\r"]


puts "============================================================"
puts "SOURCE - EPIC STYLE"
puts "============================================================"

puts [string map {"\r" "\n"} $sourceMsg]

# ============================================================
# Select CX identifier by:
#
#   assigning authority
#   identifier type
#
# Return CX.1 only.
# ============================================================

proc select_cx_id {
    fieldValue
    wantedAuthority
    wantedType
} {

    foreach repetition \
        [split $fieldValue "~"] {


        set components \
            [split $repetition "^"]


        set id \
            [lindex $components 0]


        set assigningAuthority \
            [lindex $components 3]


        # CX.4 is technically an HD datatype.
        # For now, use HD.1 / namespace ID.
        set authorityNamespace \
            [lindex \
                [split $assigningAuthority "&"] \
                0]


        set identifierType \
            [lindex $components 4]


        if {$authorityNamespace eq $wantedAuthority &&
            $identifierType eq $wantedType} {

            return $id
        }
    }


    return ""
}

proc transform_msh {segment} {

    set timestamp \
        [hl7::get_from_segment \
            $segment \
            "MSH-7"]


    set messageCode \
        [hl7::get_from_segment \
            $segment \
            "MSH-9.1"]


    set triggerEvent \
        [hl7::get_from_segment \
            $segment \
            "MSH-9.2"]


    set controlId \
        [hl7::get_from_segment \
            $segment \
            "MSH-10"]


    # --------------------------------------------------------
    # Destination-specific MSH.
    #
    # Clearly visible from the example:
    #
    #   EPIC       -> ADM
    #   TSH        -> Admitting
    #   ADT^A08^... -> ADT^A08
    #   T          -> P
    #   2.4        -> 2.2
    #   MSH-15     -> AL
    #   MSH-16     -> NE
    # --------------------------------------------------------

    return \
        "MSH|^~\\&|ADM|Admitting|||$timestamp||$messageCode^$triggerEvent|$controlId|P|2.2|||AL|NE"
}



proc transform_evn {segment} {

    set eventType \
        [hl7::get_from_segment \
            $segment \
            "EVN-1"]


    set eventTimestamp \
        [hl7::get_from_segment \
            $segment \
            "EVN-2"]


    return \
        "EVN|$eventType|$eventTimestamp"
}

proc transform_pid {segment} {

    set output \
        [new_segment PID 18]


    # --------------------------------------------------------
    # PID-1
    # --------------------------------------------------------

    lset output 1 \
        [hl7::get_from_segment \
            $segment \
            "PID-1"]


    # --------------------------------------------------------
    # PID-3
    #
    # Source may contain multiple CX repetitions.
    #
    # Destination gets one selected MRN.
    # --------------------------------------------------------

    set pid3 \
        [hl7::get_from_segment \
            $segment \
            "PID-3"]


    set mrn \
        [select_cx_id \
            $pid3 \
            MT \
            MR]


    if {$mrn eq ""} {

        error \
            "Required MT/MR identifier not found in PID-3"
    }


    lset output 3 $mrn


    # --------------------------------------------------------
    # PID-5
    #
    # Keep surname + given name only.
    # --------------------------------------------------------

    set sourceName \
        [hl7::get_from_segment \
            $segment \
            "PID-5"]


    set nameParts \
        [split $sourceName "^"]


    set simpleName \
        "[lindex $nameParts 0]^[lindex $nameParts 1]"


    lset output 5 \
        $simpleName


    # --------------------------------------------------------
    # Preserve selected demographics.
    # --------------------------------------------------------

    lset output 7 \
        [hl7::get_from_segment \
            $segment \
            "PID-7"]


    lset output 8 \
        [hl7::get_from_segment \
            $segment \
            "PID-8"]


    lset output 11 \
        [hl7::get_from_segment \
            $segment \
            "PID-11"]


    lset output 15 \
        [hl7::get_from_segment \
            $segment \
            "PID-15"]


    lset output 18 \
        [hl7::get_from_segment \
            $segment \
            "PID-18"]


    return [join $output "|"]
}

proc transform_pv1 {segment} {

    set output \
        [new_segment PV1 50]


    # --------------------------------------------------------
    # PV1-1
    # --------------------------------------------------------

    lset output 1 \
        [hl7::get_from_segment \
            $segment \
            "PV1-1"]


    # --------------------------------------------------------
    # PV1-2
    #
    # Example source representation:
    #
    #     I/P
    #
    # destination:
    #
    #     I
    # --------------------------------------------------------

    set patientClass \
        [hl7::get_from_segment \
            $segment \
            "PV1-2"]


    if {$patientClass eq "I/P"} {

        set patientClass "I"
    }


    lset output 2 \
        $patientClass


    # --------------------------------------------------------
    # PV1-3
    #
    # Keep only first three PL components:
    #
    # source:
    #
    #   7S100^7S100HW^02^TSH20001...
    #
    # output:
    #
    #   7S100^7S100HW^02
    # --------------------------------------------------------

    set sourceLocation \
        [hl7::get_from_segment \
            $segment \
            "PV1-3"]


    set locationParts \
        [split $sourceLocation "^"]


    set destinationLocation \
        [join \
            [lrange $locationParts 0 2] \
            "^"]


    lset output 3 \
        $destinationLocation


    # --------------------------------------------------------
    # Destination-specific mapped value.
    #
    # We can see an L in this position in the example.
    # The real mapping rule should ultimately come from the
    # interface specification rather than from this photograph.
    # --------------------------------------------------------

    lset output 4 \
        "L"


    # --------------------------------------------------------
    # PV1-7
    #
    # Destination keeps provider ID rather than full XCN.
    # --------------------------------------------------------

    set attending \
        [hl7::get_from_segment \
            $segment \
            "PV1-7"]


    lset output 7 \
        [lindex \
            [split $attending "^"] \
            0]


    # --------------------------------------------------------
    # Other selected destination fields.
    #
    # These represent the projection pattern.
    # --------------------------------------------------------

    lset output 14 \
        [hl7::get_from_segment \
            $segment \
            "PV1-14"]


    set admitting \
        [hl7::get_from_segment \
            $segment \
            "PV1-17"]


    lset output 17 \
        [lindex \
            [split $admitting "^"] \
            0]


    foreach fieldNumber {
        19
        20
        21
        42
        44
        50
    } {

        lset output \
            $fieldNumber \
            [hl7::get_from_segment \
                $segment \
                "PV1-$fieldNumber"]
    }


    return [join $output "|"]
}


proc transform_epic_to_med2020 {msg} {

    set output {}

    set droppedSegments {}


    foreach segment [split $msg "\r"] {

        set segmentType \
            [hl7::segment_name $segment]


        switch -exact -- $segmentType {

            MSH {

                lappend output \
                    [transform_msh $segment]
            }


            EVN {

                lappend output \
                    [transform_evn $segment]
            }


            PID {

                lappend output \
                    [transform_pid $segment]
            }


            PV1 {

                lappend output \
                    [transform_pv1 $segment]
            }


            default {

                # --------------------------------------------
                # Explicitly drop everything else.
                #
                # This models the major reduction visible
                # between the Epic and post-engine messages.
                # --------------------------------------------

                lappend droppedSegments \
                    $segmentType
            }
        }
    }


    # --------------------------------------------------------
    # Destination-specific custom segment.
    # --------------------------------------------------------

    lappend output \
        "ZID|1"


    return [dict create \
        message \
            [join $output "\r"] \
        droppedSegments \
            $droppedSegments]
}

# ============================================================
# RUN TRANSFORMATION
# ============================================================

set result \
    [transform_epic_to_med2020 \
        $sourceMsg]


set destinationMsg \
    [dict get $result message]


puts ""
puts "============================================================"
puts "DESTINATION - POST ENGINE"
puts "============================================================"

puts [string map {"\r" "\n"} $destinationMsg]


puts ""
puts "============================================================"
puts "DROPPED SOURCE SEGMENTS"
puts "============================================================"


foreach segmentType \
    [dict get $result droppedSegments] {

    puts "Dropped: $segmentType"
}	


