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



proc get_config {userArgsVar key defaultValue} {

    # userArgsVar is the NAME of the caller's variable.
    #
    # Example:
    #
    #     get_config userArgs DEBUG 0
    #
    # upvar lets us work with caller's userArgs variable.

    upvar 1 $userArgsVar userArgs


    if {[keylget userArgs $key value]} {
        return $value
    }


    return $defaultValue
}




# ============================================================
# 5. CLOVERLEAF TPS PROC
# ============================================================


proc tps_oru_transform {args} {

    keylget args MODE mode


    switch -exact -- $mode {

        start {

            puts "TPS starting"

            return {}
        }


        run {

            # -----------------------------------------------
            # Cloverleaf message handle
            # -----------------------------------------------

            if {![keylget args MSGID mh]} {

                error "MSGID missing"
            }


            # -----------------------------------------------
            # Cloverleaf configured User Arguments
            # -----------------------------------------------

            set userArgs {}

            if {[keylget args ARGS suppliedArgs]} {

                set userArgs $suppliedArgs
            }


            # -----------------------------------------------
            # Read configuration
            # -----------------------------------------------

            set threshold \
                [get_config \
                    userArgs \
                    POTASSIUM_THRESHOLD \
                    5.5]


            set debug \
                [get_config \
                    userArgs \
                    DEBUG \
                    0]


            set expectedType \
                [get_config \
                    userArgs \
                    MESSAGE_TYPE \
                    ORU]


            set expectedTrigger \
                [get_config \
                    userArgs \
                    TRIGGER_EVENT \
                    R01]


            # -----------------------------------------------
            # Validate threshold
            # -----------------------------------------------

            if {![string is double -strict $threshold]} {

                error \
                    "Invalid POTASSIUM_THRESHOLD <$threshold>"
            }


            if {$debug} {

                puts "CONFIG:"
                puts "  threshold = $threshold"
                puts "  type      = $expectedType"
                puts "  trigger   = $expectedTrigger"
            }


            # -----------------------------------------------
            # Get actual message
            # -----------------------------------------------

            set msg [msgget $mh]


            # -----------------------------------------------
            # Use our hl7_utils package
            # -----------------------------------------------

            set typeInfo \
                [hl7::get_message_type_components $msg]


            set messageCode \
                [dict get $typeInfo messageCode]

            set triggerEvent \
                [dict get $typeInfo triggerEvent]


            # -----------------------------------------------
            # Configurable filtering
            # -----------------------------------------------

            if {$messageCode ne $expectedType ||
                $triggerEvent ne $expectedTrigger} {

                return [list "CONTINUE $mh"]
            }


            # -----------------------------------------------
            # Configurable transformation
            # -----------------------------------------------

            set newMsg \
                [transform_oru $msg $threshold]


            msgset $mh $newMsg


            return [list "CONTINUE $mh"]
        }


        shutdown {

            puts "TPS shutting down"

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
	# Simulate configured Cloverleaf User Arguments
	# --------------------------------------------------------

	set userArgs {}

	keylset userArgs \
	    POTASSIUM_THRESHOLD 5.5 \
	    MESSAGE_TYPE ORU \
	    TRIGGER_EVENT R01 \
	    DEBUG 1

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
        MSGID $mh \
	ARGS $userArgs

    puts ""
    puts "=== RUN ARGS ==="
    puts $runArgs

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
