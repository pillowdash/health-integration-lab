# Lab 27: Omnicell ZPM item exclusion filter (standalone Tcl 8.6).
# Context: Epic Bridges AIP 334617 / TST, message 5678, ZPM-6=PTOWNOVERNITE.
# This is a training decision engine, NOT a drop-in Cloverleaf TPS procedure.
# In real Cloverleaf, an adapter must translate KILL/CONTINUE/REVIEW into the
# engine's documented message-handle disposition and error-routing behavior.

namespace eval ::omnicellZpm {}

# Read exact item IDs as strings. In particular, 00000000 is NOT a number.
proc ::omnicellZpm::readBlocklist {filename} {
    set fh [open $filename r]
    try {
        set contents [read $fh]
    } finally {
        close $fh
    }

    set ids [dict create]
    foreach rawLine [split $contents "\n"] {
        # The file is expected to contain one ID per line; only remove CR/LF.
        set line [string trimright $rawLine "\r"]
        if {[string trim $line] eq "" || [string match "#*" [string trimleft $line]]} {
            continue
        }
        if {[dict exists $ids $line]} {
            error "Duplicate item ID in blocklist: <$line>"
        }
        dict set ids $line 1
    }
    return $ids
}

proc ::omnicellZpm::decision {action reason {itemId ""} {transaction ""}} {
    return [dict create action $action reason $reason item_id $itemId transaction $transaction]
}

# mode ALL:       exclude listed item IDs for any ZPM transaction type.
# mode LOAD_ONLY: exclude listed item IDs only when ZPM-1 = L.
# Return a Tcl dict: action (KILL / CONTINUE / REVIEW), reason, item_id, transaction.
proc ::omnicellZpm::filter {hl7 blocklist {mode ALL}} {
    if {$mode ni {ALL LOAD_ONLY}} {
        error "Unknown filter mode <$mode>: expected ALL or LOAD_ONLY"
    }

    # Support both actual HL7 CR segment separators and readable LF samples,
    # as well as minimal MLLP wrappers (VT at start, FS at end).
    set normalized [string map [list "\r\n" "\n" "\r" "\n" "\x0b" "" "\x1c" ""] $hl7]
    set msh ""
    set zpms [list]
    foreach segment [split $normalized "\n"] {
        set segment [string trim $segment " \t\n"]
        if {[string match "MSH|*" $segment]} {
            set msh $segment
        } elseif {[string match "ZPM|*" $segment]} {
            lappend zpms $segment
        }
    }

    if {$msh eq ""} {
        return [decision REVIEW "Missing MSH segment"]
    }
    set mshFields [split $msh "|"]
    # MSH is special: after 'MSH|', list index 8 is HL7 MSH-9.
    if {[llength $mshFields] <= 8 || [lindex $mshFields 8] eq ""} {
        return [decision REVIEW "Missing MSH-9 message type"]
    }
    if {[lindex $mshFields 8] ne "ZPM^ZPM"} {
        return [decision CONTINUE "Not a ZPM^ZPM message"]
    }
    if {[llength $zpms] == 0} {
        return [decision REVIEW "ZPM^ZPM message has no ZPM segment"]
    }

    foreach segment $zpms {
        set fields [split $segment "|"]
        # For an ordinary ZPM segment, list index 1 = ZPM-1, index 6 = ZPM-6.
        if {[llength $fields] <= 6} {
            return [decision REVIEW "ZPM segment has no ZPM-6 field"]
        }
        set transaction [lindex $fields 1]
        set itemId [lindex $fields 6]
        if {$itemId eq ""} {
            return [decision REVIEW "ZPM-6 item ID is empty" $itemId $transaction]
        }
        if {$mode eq "LOAD_ONLY" && $transaction ne "L"} {
            continue
        }
        if {[dict exists $blocklist $itemId]} {
            return [decision KILL "Item ID is on exclusion list" $itemId $transaction]
        }
    }
    return [decision CONTINUE "No ZPM item ID matched the active exclusion rule"]
}

# CLI: tclsh tcl/tps/27_omnicell_zpm_item_filter.tcl <hl7-file> [ALL|LOAD_ONLY]
if {[info exists ::argv0] && [file normalize [info script]] eq [file normalize $::argv0]} {
    if {[llength $::argv] < 1 || [llength $::argv] > 2} {
        puts stderr "Usage: tclsh [info script] <message.hl7> ?ALL|LOAD_ONLY?"
        exit 2
    }
    set thisDir [file dirname [file normalize [info script]]]
    set blockfile [file join $thisDir .. data omnicell_zpm_blocklist.txt]
    set ids [::omnicellZpm::readBlocklist $blockfile]
    set messageFile [lindex $::argv 0]
    set mode ALL
    if {[llength $::argv] == 2} {
        set mode [lindex $::argv 1]
    }
    set inputHandle [open $messageFile r]
    try {
        set msg [read $inputHandle]
    } finally {
        close $inputHandle
    }
    set result [::omnicellZpm::filter $msg $ids $mode]
    puts "Mode: $mode"
    puts "Configured item IDs: [dict size $ids]"
    puts "Decision: [dict get $result action]"
    puts "Item ID:  [dict get $result item_id]"
    puts "ZPM-1:   [dict get $result transaction]"
    puts "Reason:  [dict get $result reason]"
}
