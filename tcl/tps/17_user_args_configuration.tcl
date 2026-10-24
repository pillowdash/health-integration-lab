# ============================================================
# LESSON 17
#
# Cloverleaf TPS User Arguments / configuration
#
# Goal:
#
# Do NOT hard-code:
#
#     potassiumThreshold = 5.5
#     expectedFacility   = TSH
#     debug              = 1
#
# Instead pass them into the TPS as configuration.
# ============================================================

package require Tclx

lappend auto_path [file normalize "tcl/lib"]
package require hl7utils

# ============================================================
# 1. BUILD USER ARGUMENTS
# ============================================================

set userArgs {}

keylset userArgs \
    POTASSIUM_THRESHOLD 5.5 \
    FACILITY TSH \
    MESSAGE_TYPE ORU \
    TRIGGER_EVENT R01 \
    DEBUG 1


puts "=== USER ARGUMENTS ==="
puts $userArgs

keylget userArgs POTASSIUM_THRESHOLD threshold
keylget userArgs FACILITY facility
keylget userArgs DEBUG debug

puts "Threshold = $threshold"
puts "Facility  = $facility"
puts "Debug     = $debug"


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


puts ""
puts "=== DEFAULT VALUES ==="

puts "DEBUG = [get_config userArgs DEBUG 0]"

puts "LOG_LEVEL = [get_config userArgs LOG_LEVEL INFO]"


proc require_config {userArgsVar key} {

    upvar 1 $userArgsVar userArgs


    if {![keylget userArgs $key value]} {

        error "Required TPS configuration <$key> is missing"
    }


    return $value
}


set threshold \
    [require_config userArgs POTASSIUM_THRESHOLD]

puts "threshold = $threshold"

#require_config userArgs UNKNOWN_SETTING


proc validate_config {userArgsVar} {

    upvar 1 $userArgsVar userArgs


    set threshold \
        [require_config userArgs POTASSIUM_THRESHOLD]


    if {![string is double -strict $threshold]} {

        error \
            "POTASSIUM_THRESHOLD must be numeric; received <$threshold>"
    }


    set debug \
        [get_config userArgs DEBUG 0]


    if {![string is boolean -strict $debug]} {

        error \
            "DEBUG must be boolean; received <$debug>"
    }


    return 1
}

validate_config userArgs

# ============================================================
# 2. SIMULATE CLOVERLEAF TPS ARGUMENTS
# ============================================================

set tpsArgs {}

keylset tpsArgs \
    MODE run \
    MSGID mh_17001 \
    ARGS $userArgs


puts ""
puts "=== TPS ARGUMENTS ==="

puts $tpsArgs


keylget tpsArgs MODE mode
keylget tpsArgs MSGID mh
keylget tpsArgs ARGS configuredArgs


puts ""
puts "MODE  = $mode"
puts "MSGID = $mh"

puts ""
puts "Configured user args:"
puts $configuredArgs

set threshold \
    [get_config configuredArgs POTASSIUM_THRESHOLD 5.5]

puts "Threshold = $threshold"
