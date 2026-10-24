# ============================================================================
# olis_tsh_transform.tcl
# Core OLIS outbound ORU transformation library for Joseph Brant Hospital.
#
# Designed to run under plain Tcl for unit testing and inside Infor Cloverleaf.
# It deliberately avoids engine-specific commands except optional echo logging.
#
# Mapping hook:
#   For rules that require the OLIS SQL mapping table/stored procedure, define:
#
#     proc olis_db_lookup {field incomingValue} {
#         # Return a 2-element Tcl list: {OutgoingCode OutgoingDescription}
#         # Example: return [list "14683-7" "CREATININE:SCNC:PT:URINE:QN"]
#     }
#
# If a required mapping is encountered and olis_db_lookup is not defined,
# transformation stops with an error rather than silently sending bad data.
# ============================================================================

namespace eval olis {
    variable TSH_OID "2.16.840.1.113883.3.59.1:4014"
    variable JBS_OID "2.16.840.1.113883.3.59.1:4180"

    variable TSH_ORG_XON "Joseph Brant Hospital^^^^^&2.16.840.1.113883.3.59.1:4014&ISO"
    variable TSH_PERFORMING_XON "Joseph Brant Hospital^^^^&2.16.840.1.113883.3.59.1:4014&ISO"
    variable JBS_PERFORMING_XON "Hamilton Health Sciences - Hamilton General Site^^^^^&2.16.840.1.113883.3.59.1:4180&ISO"

    variable TSH_ADDRESS "1245 Lakeshore Rd.^^Burlington^ON^L7S 0A2^CAN^B"
    variable JBS_ADDRESS "237 Barton Street East^^Hamilton^ON^L8L 2X2^CAN^B"

    variable ON_AUTHORITY "ON&Ontario&HL70347"

    # Current workbook has two conflicting BLG notes. The numbered change item
    # says BLG is at end of message; use that as the default. Set to
    # "before_each_orc" only if the older note is confirmed to be authoritative.
    variable BLG_MODE "end"

    # Workbook has two rows both labelled PV1-7 (Attending and Admitting).
    # Therefore this code transforms PV1-7 once. If the intended admitting field
    # is actually PV1-17, set this flag to 1 after confirmation.
    variable ALSO_TRANSFORM_PV1_17 0
}

# ---------------------------------------------------------------------------
# Logging: Cloverleaf has echo; plain tclsh does not.
# ---------------------------------------------------------------------------
proc olis::log {level message} {
    set line "OLIS/$level: $message"
    if {[llength [info commands echo]] > 0} {
        echo $line
    } else {
        puts stderr $line
    }
}

# ---------------------------------------------------------------------------
# HL7 low-level helpers
# ---------------------------------------------------------------------------
proc olis::segment_name {segment} {
    return [string range $segment 0 2]
}

proc olis::field_index {segmentName fieldNumber} {
    if {$segmentName eq "MSH"} {
        if {$fieldNumber == 1} {
            return -1
        }
        return [expr {$fieldNumber - 1}]
    }
    return $fieldNumber
}

proc olis::get_field {segment fieldNumber {fs "|"}} {
    set name [olis::segment_name $segment]
    if {$name eq "MSH" && $fieldNumber == 1} {
        return $fs
    }
    set fields [split $segment $fs]
    set idx [olis::field_index $name $fieldNumber]
    if {$idx < 0 || $idx >= [llength $fields]} {
        return ""
    }
    return [lindex $fields $idx]
}

proc olis::set_field {segment fieldNumber newValue {fs "|"}} {
    set name [olis::segment_name $segment]
    if {$name eq "MSH" && $fieldNumber == 1} {
        error "Changing MSH-1 is not supported"
    }
    set fields [split $segment $fs]
    set idx [olis::field_index $name $fieldNumber]
    while {[llength $fields] <= $idx} {
        lappend fields ""
    }
    lset fields $idx $newValue
    return [join $fields $fs]
}

proc olis::get_component {value componentNumber {cs "^"}} {
    if {$value eq ""} { return "" }
    set parts [split $value $cs]
    set idx [expr {$componentNumber - 1}]
    if {$idx < 0 || $idx >= [llength $parts]} { return "" }
    return [lindex $parts $idx]
}

proc olis::set_component {value componentNumber newValue {cs "^"}} {
    set parts [split $value $cs]
    set idx [expr {$componentNumber - 1}]
    while {[llength $parts] <= $idx} {
        lappend parts ""
    }
    lset parts $idx $newValue
    return [join $parts $cs]
}

proc olis::get_subcomponent {value subNumber {ss "&"}} {
    if {$value eq ""} { return "" }
    set parts [split $value $ss]
    set idx [expr {$subNumber - 1}]
    if {$idx < 0 || $idx >= [llength $parts]} { return "" }
    return [lindex $parts $idx]
}

proc olis::set_subcomponent {value subNumber newValue {ss "&"}} {
    set parts [split $value $ss]
    set idx [expr {$subNumber - 1}]
    while {[llength $parts] <= $idx} {
        lappend parts ""
    }
    lset parts $idx $newValue
    return [join $parts $ss]
}

proc olis::first_subcomponent {value} {
    return [lindex [split $value "&"] 0]
}

proc olis::digits_only {value} {
    return [regexp {^[0-9]+$} $value]
}

proc olis::pad_left_zero {value width} {
    set value [string trim $value]
    while {[string length $value] < $width} {
        set value "0$value"
    }
    return $value
}

# ---------------------------------------------------------------------------
# Database mapping hook
# ---------------------------------------------------------------------------
proc olis::mapping_lookup {field incomingValue} {
    if {[llength [info commands olis_db_lookup]] == 0} {
        error "Mapping required for $field value <$incomingValue>, but proc olis_db_lookup is not configured"
    }
    set result [olis_db_lookup $field $incomingValue]
    if {[llength $result] < 2} {
        error "olis_db_lookup must return {OutgoingCode OutgoingDescription}; got <$result>"
    }
    return [lrange $result 0 1]
}

# ---------------------------------------------------------------------------
# PID-3 Patient Identifier
# Latest documented behavior used here:
#   1) Prefer JHN repetition where PID-3.4=ON.
#   2) If no ON JHN exists, send MR repetition (August 19 change).
#   3) If neither exists but some JHN exists, fall back to first JHN and WARN.
# ---------------------------------------------------------------------------
proc olis::transform_pid3 {pid3} {
    variable TSH_OID

    set reps [split $pid3 "~"]
    set firstJhn ""
    set onJhn ""
    set mr ""
    set hasJhn 0

    foreach rep $reps {
        set idType [olis::get_component $rep 5]
        set assigning [olis::get_component $rep 4]

        if {$idType eq "JHN"} {
            set hasJhn 1
            if {$firstJhn eq ""} { set firstJhn $rep }
            if {$assigning eq "ON" && $onJhn eq ""} { set onJhn $rep }
        }
        if {$idType eq "MR" && $mr eq ""} {
            set mr $rep
        }
    }

    if {$onJhn ne ""} {
        set id [olis::get_component $onJhn 1]
        return [list "${id}^^^^JHN^^^^ON&Ontario&HL70347" $hasJhn]
    }

    if {$mr ne ""} {
        set id [olis::get_component $mr 1]
        return [list "${id}^^^&${TSH_OID}&ISO^MR" $hasJhn]
    }

    if {$firstJhn ne ""} {
        olis::log WARN "PID-3 has JHN but no ON JHN and no MR; falling back to first JHN"
        set id [olis::get_component $firstJhn 1]
        set sourceAuthority [olis::get_component $firstJhn 4]
        set desc $sourceAuthority
        if {$sourceAuthority eq "ON"} { set desc "Ontario" }
        return [list "${id}^^^^JHN^^^^${sourceAuthority}&${desc}&HL70347" $hasJhn]
    }

    olis::log WARN "PID-3 contains neither JHN nor MR; leaving PID-3 unchanged"
    return [list $pid3 $hasJhn]
}

# PID-5.7 = U for every PID-5 repetition.
proc olis::transform_pid5 {pid5} {
    set out {}
    foreach rep [split $pid5 "~"] {
        lappend out [olis::set_component $rep 7 "U"]
    }
    return [join $out "~"]
}

# Suppress PID-11 repetitions where PID-11.6 is populated and not CAN/USA.
proc olis::transform_pid11 {pid11} {
    set out {}
    foreach rep [split $pid11 "~"] {
        set country [string toupper [string trim [olis::get_component $rep 6]]]
        if {$country ne "" && $country ne "CAN" && $country ne "USA"} {
            olis::log INFO "Suppressing PID-11 repetition with country <$country>"
            continue
        }
        lappend out $rep
    }
    return [join $out "~"]
}

# PID-13 / PID-14 XTN cleanup.
# - Phone repetitions are truncated to XTN.1..XTN.7, removing trailing serial data.
# - If XTN.7 contains 10 digits, move first 3 digits to XTN.6 and keep last 7 in XTN.7.
# - For PID-14 phone repetitions, use WPN as XTN.2 to match the documented example.
# - NET/Internet repetitions are preserved.
proc olis::transform_xtn_field {value fieldNumber} {
    set out {}
    foreach rep [split $value "~"] {
        set use [olis::get_component $rep 2]
        set equipment [olis::get_component $rep 3]

        if {$use eq "NET" || [string equal -nocase $equipment "Internet"]} {
            lappend out $rep
            continue
        }

        set parts [split $rep "^"]
        while {[llength $parts] < 7} { lappend parts "" }

        if {$fieldNumber == 14 && $equipment eq "PH"} {
            lset parts 1 "WPN"
        }

        set localNumber [lindex $parts 6]
        if {[string length $localNumber] == 10 && [olis::digits_only $localNumber]} {
            lset parts 5 [string range $localNumber 0 2]
            lset parts 6 [string range $localNumber 3 end]
        }

        # Remove documented trailing serial / extra XTN components.
        set parts [lrange $parts 0 6]
        lappend out [join $parts "^"]
    }
    return [join $out "~"]
}

proc olis::transform_pid_segment {segment fs} {
    set pid3 [olis::get_field $segment 3 $fs]
    lassign [olis::transform_pid3 $pid3] newPid3 hasJhn
    set segment [olis::set_field $segment 3 $newPid3 $fs]

    set segment [olis::set_field $segment 5 \
        [olis::transform_pid5 [olis::get_field $segment 5 $fs]] $fs]

    set segment [olis::set_field $segment 11 \
        [olis::transform_pid11 [olis::get_field $segment 11 $fs]] $fs]

    set segment [olis::set_field $segment 13 \
        [olis::transform_xtn_field [olis::get_field $segment 13 $fs] 13] $fs]

    set segment [olis::set_field $segment 14 \
        [olis::transform_xtn_field [olis::get_field $segment 14 $fs] 14] $fs]

    return [list $segment $hasJhn]
}

# ---------------------------------------------------------------------------
# XCN provider normalization used by PV1-7, OBR-16 and OBR-28.
# ---------------------------------------------------------------------------
proc olis::normalize_xcn {value} {
    variable ON_AUTHORITY
    set out {}
    foreach rep [split $value "~"] {
        if {$rep eq ""} {
            lappend out ""
            continue
        }
        set rep [olis::set_component $rep 22 $ON_AUTHORITY]
        set idType [olis::get_component $rep 13]
        switch -exact -- $idType {
            CPSO { set rep [olis::set_component $rep 13 "MDL"] }
            CNO  { set rep [olis::set_component $rep 13 "NPL"] }
            CMO  { set rep [olis::set_component $rep 13 "ML"] }
        }
        set rep [olis::set_component $rep 9 ""]
        lappend out $rep
    }
    return [join $out "~"]
}

proc olis::transform_pv1_segment {segment fs} {
    variable ALSO_TRANSFORM_PV1_17
    set segment [olis::set_field $segment 7 \
        [olis::normalize_xcn [olis::get_field $segment 7 $fs]] $fs]
    if {$ALSO_TRANSFORM_PV1_17} {
        set segment [olis::set_field $segment 17 \
            [olis::normalize_xcn [olis::get_field $segment 17 $fs]] $fs]
    }
    return $segment
}

# ---------------------------------------------------------------------------
# ORC
# ---------------------------------------------------------------------------
proc olis::transform_orc_segment {segment fs} {
    variable TSH_ORG_XON

    set orc4 [olis::get_field $segment 4 $fs]
    set orc4 [olis::set_component $orc4 3 "HL79901"]
    set segment [olis::set_field $segment 4 $orc4 $fs]

    set segment [olis::set_field $segment 12 "" $fs]
    set segment [olis::set_field $segment 21 $TSH_ORG_XON $fs]

    set orc24 [olis::get_field $segment 24 $fs]
    set orc24 [olis::set_component $orc24 7 "H"]
    set segment [olis::set_field $segment 24 $orc24 $fs]

    return $segment
}

# ---------------------------------------------------------------------------
# OBR helpers
# ---------------------------------------------------------------------------
proc olis::transform_ei {value} {
    variable TSH_OID
    set value [olis::set_component $value 3 $TSH_OID]
    set value [olis::set_component $value 4 "ISO"]
    return $value
}

proc olis::transform_obr4 {value} {
    if {[string first "+++" $value] >= 0} {
        lassign [olis::mapping_lookup "OBR-4" $value] code description
        return "${code}^${description}^HL79901"
    }

    set code [olis::get_component $value 1]
    set description [olis::get_component $value 4]
    if {$description eq ""} {
        set description [olis::get_component $value 2]
    }
    return "${code}^${description}^HL79901"
}

proc olis::transform_obr15 {value} {
    if {$value eq ""} { return "" }

    set incoming [olis::get_component $value 1]
    if {$incoming eq ""} { return $value }

    # OBR-15.4.2: component 4, subcomponent 2.
    set comp4 [olis::get_component $value 4]
    set sourceText [olis::get_subcomponent $comp4 2]

    lassign [olis::mapping_lookup "OBR-15" $incoming] code description
    set firstComponent "${code}&${description}&HL70070"

    if {$sourceText ne ""} {
        return "${firstComponent}^^^^&${sourceText}"
    }
    return $firstComponent
}

proc olis::transform_obr17 {value} {
    set value [olis::set_component $value 1 ""]
    set value [olis::set_component $value 2 "WPN"]
    set value [olis::set_component $value 3 "PH"]
    return $value
}

proc olis::transform_obr29 {value} {
    variable TSH_OID
    if {$value eq ""} { return "" }

    set components [split $value "^"]
    while {[llength $components] < 2} { lappend components "" }

    for {set i 0} {$i < 2} {incr i} {
        set component [lindex $components $i]
        if {$component ne ""} {
            set id [olis::first_subcomponent $component]
            lset components $i "${id}&&${TSH_OID}&ISO"
        }
    }
    return [join $components "^"]
}

# Returns {transformedOBR originalOBR24 originalOBR25}
proc olis::transform_obr_segment {segment fs} {
    set obr1 [olis::get_field $segment 1 $fs]
    set originalObr24 [olis::get_field $segment 24 $fs]
    set originalObr25 [olis::get_field $segment 25 $fs]

    set obr2 [olis::transform_ei [olis::get_field $segment 2 $fs]]
    set obr3 [olis::transform_ei [olis::get_field $segment 3 $fs]]

    # Workbook wording is ambiguous; the common uniqueness pattern is to append
    # "-<OBR-1>" to OBR-2.1 and OBR-3.1 for Microbiology OBRs after the first.
    if {[string equal -nocase $originalObr24 "Microbiology"] && \
        [string is integer -strict $obr1] && $obr1 > 1} {
        set id2 [olis::get_component $obr2 1]
        set id3 [olis::get_component $obr3 1]
        if {$id2 ne ""} { set obr2 [olis::set_component $obr2 1 "${id2}-${obr1}"] }
        if {$id3 ne ""} { set obr3 [olis::set_component $obr3 1 "${id3}-${obr1}"] }
    }

    set segment [olis::set_field $segment 2 $obr2 $fs]
    set segment [olis::set_field $segment 3 $obr3 $fs]
    set segment [olis::set_field $segment 4 \
        [olis::transform_obr4 [olis::get_field $segment 4 $fs]] $fs]
    set segment [olis::set_field $segment 15 \
        [olis::transform_obr15 [olis::get_field $segment 15 $fs]] $fs]
    set segment [olis::set_field $segment 16 \
        [olis::normalize_xcn [olis::get_field $segment 16 $fs]] $fs]
    set segment [olis::set_field $segment 17 \
        [olis::transform_obr17 [olis::get_field $segment 17 $fs]] $fs]
    set segment [olis::set_field $segment 24 "" $fs]
    set segment [olis::set_field $segment 28 \
        [olis::normalize_xcn [olis::get_field $segment 28 $fs]] $fs]
    set segment [olis::set_field $segment 29 \
        [olis::transform_obr29 [olis::get_field $segment 29 $fs]] $fs]

    if {[string equal -nocase $originalObr24 "POCT"]} {
        set segment [olis::set_field $segment 30 "PORT" $fs]
    }

    return [list $segment $originalObr24 $originalObr25]
}

# ---------------------------------------------------------------------------
# ZBR after every OBR
# ---------------------------------------------------------------------------
proc olis::build_zbr {obr incomingMsh4 fs} {
    variable TSH_OID
    variable JBS_OID
    variable TSH_ORG_XON
    variable TSH_PERFORMING_XON
    variable JBS_PERFORMING_XON
    variable TSH_ADDRESS
    variable JBS_ADDRESS

    set zbr "ZBR"
    set zbr [olis::set_field $zbr 2 $TSH_ORG_XON $fs]
    set zbr [olis::set_field $zbr 3 $TSH_ORG_XON $fs]
    set zbr [olis::set_field $zbr 4 $TSH_ORG_XON $fs]
    set zbr [olis::set_field $zbr 5 $TSH_ADDRESS $fs]

    if {$incomingMsh4 eq "37"} {
        set zbr [olis::set_field $zbr 6 $JBS_PERFORMING_XON $fs]
        set zbr [olis::set_field $zbr 7 $JBS_ADDRESS $fs]
        set zbr [olis::set_field $zbr 8 "Hamilton Health Sciences" $fs]
    } else {
        set zbr [olis::set_field $zbr 6 $TSH_PERFORMING_XON $fs]
        set zbr [olis::set_field $zbr 7 $TSH_ADDRESS $fs]
    }

    # ZBR-11 = OBR-1 unique sort key.
    set zbr [olis::set_field $zbr 11 [olis::get_field $obr 1 $fs] $fs]
    return $zbr
}

# ---------------------------------------------------------------------------
# OBX
# ---------------------------------------------------------------------------
proc olis::transform_obx3 {value} {
    if {[string first "+++" $value] >= 0} {
        lassign [olis::mapping_lookup "OBX-3" $value] code description
        set description [string trimright $description ":"]
        return "${code}^${description}^HL79902"
    }

    set code [olis::get_component $value 1]
    set description [olis::get_component $value 4]
    if {$description eq ""} { set description [olis::get_component $value 2] }
    set description [string trimright $description ":"]
    return "${code}^${description}^HL79902"
}

proc olis::transform_obx5_ed {value} {
    set value [olis::set_component $value 2 "TEXT"]
    set value [olis::set_component $value 4 "Base64"]
    return $value
}

proc olis::transform_obx5_cwe {value} {
    set altId [olis::get_component $value 4]
    set altText [olis::get_component $value 5]
    if {$altId eq ""} { return $value }

    # Workbook contains contradictory wording for OBX-5.2: it says both copy
    # OBX-5.5 and hardcode "(organism)". This implementation uses OBX-5.5 when
    # populated, otherwise falls back to the literal "(organism)".
    if {$altText eq ""} { set altText "(organism)" }
    return "${altId}^${altText}^HL79905"
}

# Returns transformed OBX.
proc olis::transform_obx_segment {segment fs currentObr25} {
    set obx1 [olis::get_field $segment 1 $fs]
    set originalType [olis::get_field $segment 2 $fs]

    set segment [olis::set_field $segment 3 \
        [olis::transform_obx3 [olis::get_field $segment 3 $fs]] $fs]

    # General rule: OBX-4 = OBX-1. The final-result empty-value rule below can
    # override OBX-4 back to blank.
    set segment [olis::set_field $segment 4 $obx1 $fs]

    set obx5 [olis::get_field $segment 5 $fs]

    if {$originalType eq "ED"} {
        set obx5 [olis::transform_obx5_ed $obx5]
    } elseif {$originalType eq "CWE"} {
        set obx5 [olis::transform_obx5_cwe $obx5]
    }
    set segment [olis::set_field $segment 5 $obx5 $fs]

    # Empty OBX-5 rules are based on the current OBR-25.
    if {$obx5 eq ""} {
        if {$currentObr25 eq "C"} {
            set segment [olis::set_field $segment 11 "W" $fs]
            set segment [olis::set_field $segment 2 "ST" $fs]
            set segment [olis::set_field $segment 5 "-" $fs]
        } elseif {$currentObr25 eq "F"} {
            set segment [olis::set_field $segment 11 "N" $fs]
            set segment [olis::set_field $segment 2 "" $fs]
            set segment [olis::set_field $segment 4 "" $fs]
        }
    } elseif {$originalType eq "CWE"} {
        # CWE -> CE when not overridden by empty-value rule.
        set segment [olis::set_field $segment 2 "CE" $fs]
    }

    return $segment
}

proc olis::build_zbx {obx msh7 fs} {
    set zbx "ZBX"
    set zbx [olis::set_field $zbx 1 $msh7 $fs]
    set obx1 [olis::get_field $obx 1 $fs]
    set zbx [olis::set_field $zbx 2 [olis::pad_left_zero $obx1 2] $fs]
    return $zbx
}

# ---------------------------------------------------------------------------
# NTE merge + ZNT
# ---------------------------------------------------------------------------
proc olis::merge_nte_segments {nteSegments fs} {
    if {[llength $nteSegments] == 0} { return "" }

    set first [lindex $nteSegments 0]
    set texts {}
    foreach nte $nteSegments {
        set text [olis::get_field $nte 3 $fs]
        if {$text ne ""} { lappend texts $text }
    }

    set joined [join $texts [format "%c.br%c" 92 92]]
    return [olis::set_field $first 3 $joined $fs]
}

proc olis::build_znt {incomingMsh4 fs} {
    variable TSH_OID
    variable JBS_OID
    if {$incomingMsh4 eq "37"} {
        set oid $JBS_OID
    } else {
        set oid $TSH_OID
    }
    set znt "ZNT"
    set znt [olis::set_field $znt 1 "^${oid}^ISO" $fs]
    return $znt
}

# ---------------------------------------------------------------------------
# BLG
# ---------------------------------------------------------------------------
proc olis::build_blg {fs} {
    set blg "BLG"
    return [olis::set_field $blg 3 "MOHLTC" $fs]
}

# ---------------------------------------------------------------------------
# Flush pending NTE group into output list and add ZNT.
# upvar is intentional: this helper mutates caller-owned lists.
# ---------------------------------------------------------------------------
proc olis::flush_nte_group {outVar nteVar incomingMsh4 fs} {
    upvar 1 $outVar out
    upvar 1 $nteVar pendingNtes

    if {[llength $pendingNtes] == 0} { return }

    set merged [olis::merge_nte_segments $pendingNtes $fs]
    if {$merged ne ""} {
        lappend out $merged
        lappend out [olis::build_znt $incomingMsh4 $fs]
    }
    set pendingNtes {}
}

# ---------------------------------------------------------------------------
# MAIN TRANSFORMATION
# ---------------------------------------------------------------------------
proc olis::transform_message {msg} {
    variable BLG_MODE

    # Normalize line endings to HL7 CR separators.
    set msg [string map [list "\r\n" "\r" "\n" "\r"] $msg]
    set segments [split $msg "\r"]

    # Remove empty trailing elements from processing.
    set cleanSegments {}
    foreach segment $segments {
        if {$segment ne ""} { lappend cleanSegments $segment }
    }
    set segments $cleanSegments

    if {[llength $segments] == 0 || [olis::segment_name [lindex $segments 0]] ne "MSH"} {
        error "OLIS transformation requires MSH as the first segment"
    }

    # Field separator is character 4 of MSH (Tcl index 3).
    set fs [string index [lindex $segments 0] 3]
    if {$fs eq ""} { set fs "|" }

    set msh [lindex $segments 0]
    set incomingMsh4 [olis::get_field $msh 4 $fs]
    set msh7 [olis::get_field $msh 7 $fs]

    # MSH-4 hardcode. Capture incoming MSH-4 above because later ZBR/ZNT rules
    # still depend on the source value (e.g. 37).
    set msh [olis::set_field $msh 4 "SampleConformanceID1" $fs]

    set out [list $msh]
    set pendingNtes {}
    set currentObr25 ""

    # Start from segment 2 because transformed MSH is already in out.
    for {set i 1} {$i < [llength $segments]} {incr i} {
        set segment [lindex $segments $i]
        set name [olis::segment_name $segment]

        # NTEs are collected and emitted as one merged NTE when the group ends.
        if {$name eq "NTE"} {
            lappend pendingNtes $segment
            continue
        }

        # Any non-NTE closes the preceding NTE group.
        olis::flush_nte_group out pendingNtes $incomingMsh4 $fs

        switch -exact -- $name {
            SPM {
                # Active requirement: remove SPM segment.
                continue
            }

            PID {
                lassign [olis::transform_pid_segment $segment $fs] segment hasJhn
                lappend out $segment
                if {!$hasJhn} {
                    # Create ZPD immediately after PID; ZPD-2=Y.
                    set zpd "ZPD"
                    set zpd [olis::set_field $zpd 2 "Y" $fs]
                    lappend out $zpd
                }
            }

            PV1 {
                lappend out [olis::transform_pv1_segment $segment $fs]
            }

            ORC {
                if {$BLG_MODE eq "before_each_orc"} {
                    lappend out [olis::build_blg $fs]
                }
                lappend out [olis::transform_orc_segment $segment $fs]
            }

            OBR {
                lassign [olis::transform_obr_segment $segment $fs] segment originalObr24 currentObr25
                lappend out $segment
                lappend out [olis::build_zbr $segment $incomingMsh4 $fs]
            }

            OBX {
                set segment [olis::transform_obx_segment $segment $fs $currentObr25]
                lappend out $segment
                lappend out [olis::build_zbx $segment $msh7 $fs]
            }

            default {
                lappend out $segment
            }
        }
    }

    # Flush NTE group at end of message.
    olis::flush_nte_group out pendingNtes $incomingMsh4 $fs

    # Current numbered change item says one BLG at end of message.
    if {$BLG_MODE eq "end"} {
        lappend out [olis::build_blg $fs]
    }

    return [join $out "\r"]
}

package provide olis_tsh_transform 1.0
