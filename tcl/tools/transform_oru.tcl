# ============================================================
# Standalone ORU transformation utility
# ============================================================

set scriptDir \
    [file dirname [file normalize [info script]]]

set tclRoot \
    [file normalize [file join $scriptDir ..]]

lappend auto_path \
    [file join $tclRoot lib]


package require hl7utils
package require orurules


# ============================================================
# Helpers
# ============================================================

proc read_hl7_file {filename} {

    set fp [open $filename r]

    set data [read $fp]

    close $fp


    # Normalize physical text-file lines into HL7 CR separators.
    set data [string map {
        "\r\n" "\n"
    } $data]

    set data \
        [string trimright $data "\r\n"]

    return \
        [string map {
            "\n" "\r"
        } $data]
}


proc write_hl7_file {filename msg} {

    set fp [open $filename w]

    # Store it human-readably as one segment per text line.
    puts -nonewline $fp \
        [string map {
            "\r" "\n"
        } $msg]

    close $fp
}


proc usage {} {

    puts "Usage:"

    puts "  tclsh transform_oru.tcl \\"
    puts "      --input INPUT.hl7 \\"
    puts "      --output OUTPUT.hl7 \\"
    puts "      --threshold 5.5"

    puts ""
}


proc parse_args {argv} {

    set result [dict create \
        input     "" \
        output    "" \
        threshold ""]


    set i 0


    while {$i < [llength $argv]} {

        set arg [lindex $argv $i]


        switch -exact -- $arg {

            --input {

                incr i

                if {$i >= [llength $argv]} {
                    error "--input requires a value"
                }

                dict set result input \
                    [lindex $argv $i]
            }


            --output {

                incr i

                if {$i >= [llength $argv]} {
                    error "--output requires a value"
                }

                dict set result output \
                    [lindex $argv $i]
            }


            --threshold {

                incr i

                if {$i >= [llength $argv]} {
                    error "--threshold requires a value"
                }

                set threshold \
                    [lindex $argv $i]

                if {![string is double -strict $threshold]} {
                    error "Invalid threshold <$threshold>"
                }

                dict set result threshold $threshold
            }


            --help {

                usage
                exit 0
            }


            default {

                error "Unknown option <$arg>"
            }
        }


        incr i
    }


    return $result
}


# ============================================================
# Main
# ============================================================

if {[catch {

    set config [parse_args $argv]

} err]} {

    puts stderr "ERROR: $err"

    usage

    exit 1
}


set inputFile \
    [dict get $config input]

set outputFile \
    [dict get $config output]


if {$inputFile eq ""} {

    puts stderr "ERROR: --input is required"

    usage
    exit 1
}


if {$outputFile eq ""} {

    puts stderr "ERROR: --output is required"

    usage
    exit 1
}


# Environment default.
if {[info exists env(HL7_THRESHOLD)]} {

    set threshold $env(HL7_THRESHOLD)

} else {

    set threshold 5.5
}


# Command-line override.
if {[dict get $config threshold] ne ""} {

    set threshold \
        [dict get $config threshold]
}


if {![string is double -strict $threshold]} {

    puts stderr \
        "ERROR: threshold <$threshold> is not numeric"

    exit 1
}


puts "Input     : $inputFile"
puts "Output    : $outputFile"
puts "Threshold : $threshold"


set msg \
    [read_hl7_file $inputFile]


set transformed \
    [oru::transform \
        $msg \
        $threshold]


write_hl7_file \
    $outputFile \
    $transformed


puts "Transformation complete."



