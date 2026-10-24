# ============================================================
# LESSON 16
# Production-style Cloverleaf TPS skeleton
#
# Concepts:
#
#   MODE
#   MSGID
#   keylget
#   msgget / msgset
#   CONTINUE / KILL
#   catch
#   lifecycle: start / run / shutdown
#
# This script can also run under normal Linux tclsh.
# ============================================================

package require Tclx

lappend auto_path [file normalize "tcl/lib"]
package require hl7utils

puts "hl7utils loaded:"
puts [package present hl7utils]

puts ""
puts "Our HL7 commands:"

foreach cmd [lsort [info commands hl7::*]] {
    puts "  $cmd"
}

puts ""

set parsed [hl7::parse_path "OBR-4.1"]

puts $parsed

puts "segment   = [dict get $parsed segment]"
puts "field     = [dict get $parsed field]"
puts "component = [dict get $parsed component]"

puts ""
set parsed [hl7::parse_path "OBX-5"]

puts "segment   = [dict get $parsed segment]"
puts "field     = [dict get $parsed field]"
puts "component = <[dict get $parsed component]>"

# ============================================================
# 1. LOCAL CLOVERLEAF MOCK
#
# In real Cloverleaf, msgget/msgset already exist.
#
# Under ordinary tclsh they don't, so create them only
# when they are missing.
# ============================================================

if {[llength [info commands msgget]] == 0} {

    puts "INFO: Cloverleaf msgget not found - using local mock"

    array set ::mockMessages {}

    proc msgget {mh} {

        if {![info exists ::mockMessages($mh)]} {
            error "Unknown message handle: $mh"
        }

        return $::mockMessages($mh)
    }


    proc msgset {mh msg} {

        set ::mockMessages($mh) $msg
    }


    proc mock_create_message {mh msg} {

        set ::mockMessages($mh) $msg
    }
}


# ============================================================
# 2. SIMPLE LOGGER
# ============================================================

proc log_message {level text} {

    set timestamp \
        [clock format [clock seconds] \
            -format "%Y-%m-%d %H:%M:%S"]

    puts "$timestamp \[$level\] $text"
}


# ============================================================
# 3. BASIC HL7 HELPERS
# ============================================================

# namespace eval hl7 {}
# moved to tcl/lib/hl7_utils.tcl



# ============================================================
# 4. BUSINESS TRANSFORMATION
#
# Demo:
#
# If OBX-3.1 = K and OBX-5 > 5.5
# then set OBX-8 = H.
# ============================================================

proc transform_oru {msg threshold} {

    set output {}


    foreach segment [split $msg "\r"] {

        set segmentType \
            [lindex [split $segment "|"] 0]


        if {$segmentType ne "OBX"} {

            lappend output $segment
            continue
        }


        set code \
            [hl7::get_from_segment $segment "OBX-3.1"]

        set value \
            [hl7::get_from_segment $segment "OBX-5"]


        if {$code eq "K" &&
            [string is double -strict $value] &&
            $value > $threshold} {
            #$value > 5.5} {

            log_message INFO \
                "High potassium detected: $value"

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

# ============================================================
# 5. CLOVERLEAF TPS PROC
# ============================================================

proc tps_oru_transform {args} {

    # --------------------------------------------------------
    # Get MODE from Cloverleaf keyed-list arguments.
    # --------------------------------------------------------

    keylget args MODE mode


    switch -exact -- $mode {

        start {

            log_message INFO \
                "tps_oru_transform starting"

            return {}
        }


        run {

            # ------------------------------------------------
            # MSGID is the Cloverleaf message handle.
            # ------------------------------------------------

            if {![keylget args MSGID mh]} {

                log_message ERROR \
                    "MODE=run but MSGID is missing"

                return {}
            }


            # ------------------------------------------------
            # Get actual HL7 payload.
            # ------------------------------------------------

            if {[catch {

                set msg [msgget $mh]

            } err]} {

                log_message ERROR \
                    "msgget failed for $mh: $err"

                return [list "KILL $mh"]
            }


            # ------------------------------------------------
            # Inspect MSH-9.
            # ------------------------------------------------

            set msh [hl7::get_segment $msg MSH]

            if {$msh eq ""} {

                log_message ERROR \
                    "Message $mh has no MSH segment"

                return [list "KILL $mh"]
            }


            set messageCode \
                [hl7::get_from_segment $msh "MSH-9.1"]

            set triggerEvent \
                [hl7::get_from_segment $msh "MSH-9.2"]


            log_message INFO \
                "Received $messageCode^$triggerEvent handle=$mh"


            # ------------------------------------------------
            # Only transform ORU^R01.
            #
            # Other messages continue unchanged.
            # ------------------------------------------------

            if {$messageCode ne "ORU" ||
                $triggerEvent ne "R01"} {

                log_message INFO \
                    "Message not ORU^R01 - passing unchanged"

                return [list "CONTINUE $mh"]
            }


            # ------------------------------------------------
            # Transform.
            # ------------------------------------------------

            if {[catch {

                set newMsg [transform_oru $msg 5.5]

            } err options]} {

                log_message ERROR \
                    "Transformation failed: $err"

                return [list "KILL $mh"]
            }


            # ------------------------------------------------
            # Put transformed data back into Cloverleaf
            # message object.
            # ------------------------------------------------

            if {[catch {

                msgset $mh $newMsg

            } err]} {

                log_message ERROR \
                    "msgset failed: $err"

                return [list "KILL $mh"]
            }


            log_message INFO \
                "Transformation complete for $mh"


            return [list "CONTINUE $mh"]
        }


        shutdown {

            log_message INFO \
                "tps_oru_transform shutting down"

            return {}
        }


        default {

            log_message INFO \
                "MODE=$mode ignored"

            return {}
        }
    }
}

# ============================================================
# 6. LOCAL TEST DRIVER
#
# Only run this if we're outside Cloverleaf.
# ============================================================

if {[info exists ::mockMessages]} {

    puts ""
    puts "============================================================"
    puts "LOCAL TPS TEST"
    puts "============================================================"


    set testMsg [join [list \
        "MSH|^~\\&|EPIC|TSH|LAB|TSH|202610062100||ORU^R01|MSG16001|P|2.5" \
        "PID|1||123456^^^TSH^MR||SMITH^JOHN" \
        "OBR|1|ORD1002|LAB1002|BMP^Basic Metabolic Panel" \
        "OBX|1|NM|NA^Sodium||140|mmol/L|135-145|N|||F" \
        "OBX|2|NM|K^Potassium||5.8|mmol/L|3.5-5.1|N|||F" \
    ] "\r"]


    set mh "mh_16001"

    mock_create_message $mh $testMsg


    # --------------------------------------------------------
    # Simulate Cloverleaf MODE=start
    # --------------------------------------------------------

    set startArgs {}

    keylset startArgs MODE start

    tps_oru_transform {*}$startArgs


    # --------------------------------------------------------
    # BEFORE
    # --------------------------------------------------------

    puts ""
    puts "=== BEFORE ==="

    puts [string map \
        {"\r" "\n"} \
        [msgget $mh]]


    # --------------------------------------------------------
    # Simulate Cloverleaf MODE=run
    # --------------------------------------------------------

    set runArgs {}

    keylset runArgs \
        MODE run \
        MSGID $mh


    set disposition \
        [tps_oru_transform {*}$runArgs]


    puts ""
    puts "Disposition = $disposition"


    # --------------------------------------------------------
    # AFTER
    # --------------------------------------------------------

    puts ""
    puts "=== AFTER ==="

    puts [string map \
        {"\r" "\n"} \
        [msgget $mh]]


    # --------------------------------------------------------
    # Simulate shutdown
    # --------------------------------------------------------

    set shutdownArgs {}

    keylset shutdownArgs MODE shutdown

    tps_oru_transform {*}$shutdownArgs
}
