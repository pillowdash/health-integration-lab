# ============================================================
# LESSON 21
# Command-line arguments + environment variables
# ============================================================

puts "============================================================"
puts "1. COMMAND-LINE BASICS"
puts "============================================================"

puts "argv0 = $argv0"
puts "argc  = $argc"
puts "argv  = <$argv>"

if {$argc >= 3} {

    set messageType [lindex $argv 0]
    set trigger     [lindex $argv 1]
    set threshold   [lindex $argv 2]

    puts "Message type = $messageType"
    puts "Trigger      = $trigger"
    puts "Threshold    = $threshold"
}


puts ""
puts "============================================================"
puts "2. LOOP THROUGH argv"
puts "============================================================"

set index 0

foreach arg $argv {

    puts "argv index $index = <$arg>"

    incr index
}


puts ""
puts "============================================================"
puts "3. ENVIRONMENT VARIABLES"
puts "============================================================"

if {[info exists env(HOME)]} {
    puts "HOME = $env(HOME)"
}

if {[info exists env(PATH)]} {
    puts "PATH exists"
}

if {[info exists env(USER)]} {
    puts "USER = $env(USER)"
}



proc get_env {name defaultValue} {

    global env


    if {[info exists env($name)]} {
        return $env($name)
    }


    return $defaultValue
}



# ============================================================
# Simple command-line option parser
# ============================================================

proc parse_args {argv} {

    set config [dict create \
        type      ORU \
        trigger   R01 \
        threshold "" \
        debug     0 \
        input     "" \
        output    ""]

    set threshold \
        [get_env HL7_THRESHOLD 5.5]


    if {[dict get $config threshold] ne ""} {

        set threshold \
            [dict get $config threshold]
    }

    set i 0

    while {$i < [llength $argv]} {

        set arg [lindex $argv $i]


        switch -exact -- $arg {

            --type {

                incr i

                if {$i >= [llength $argv]} {
                    error "--type requires a value"
                }

                dict set config type \
                    [lindex $argv $i]
            }


            --trigger {

                incr i

                if {$i >= [llength $argv]} {
                    error "--trigger requires a value"
                }

                dict set config trigger \
                    [lindex $argv $i]
            }


            --threshold {

                incr i

                if {$i >= [llength $argv]} {
                    error "--threshold requires a value"
                }

                set value [lindex $argv $i]

                if {![string is double -strict $value]} {
                    error \
                        "--threshold must be numeric; got <$value>"
                }

                dict set config threshold $value
            }


            --input {

                incr i

                if {$i >= [llength $argv]} {
                    error "--input requires a filename"
                }

                dict set config input \
                    [lindex $argv $i]
            }


            --output {

                incr i

                if {$i >= [llength $argv]} {
                    error "--output requires a filename"
                }

                dict set config output \
                    [lindex $argv $i]
            }


            --debug {

                dict set config debug 1
            }


            --help {

                dict set config help 1
            }


            default {

                error "Unknown option <$arg>"
            }
        }


        incr i
    }


    return $config
}

if {[catch {

    set config [parse_args $argv]

} err]} {

    puts stderr "ERROR: $err"

    exit 1
}

puts ""
puts "============================================================"
puts "PARSED CONFIG"
puts "============================================================"

puts "Type      = [dict get $config type]"
puts "Trigger   = [dict get $config trigger]"
puts "Threshold = [dict get $config threshold]"
puts "Debug     = [dict get $config debug]"
puts "Input     = [dict get $config input]"
puts "Output    = [dict get $config output]"



