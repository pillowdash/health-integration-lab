# ============================================================
# LESSON 19
#
# File Access + HL7 Regression Testing
# ============================================================


set scriptDir \
    [file dirname [file normalize [info script]]]

set tclRoot \
    [file normalize [file join $scriptDir ..]]

set libDir \
    [file join $tclRoot lib]

set testDataDir \
    [file join $tclRoot testdata]


lappend auto_path $libDir


package require hl7utils
package require orurules


# ============================================================
# READ A FILE
# ============================================================

proc read_text_file {filename} {

    set fp [open $filename r]

    set data [read $fp]

    close $fp

    return $data
}

set start [clock milliseconds]

set contents \
    [read_text_file \
        [file join $testDataDir oru_high_k_input.hl7]]


proc read_hl7_file {filename} {

    set data [read_text_file $filename]


    # Normalize Windows CRLF first.
    #
    # \r\n -> \n
    set data \
        [string map {
            "\r\n" "\n"
        } $data]


    # Remove whitespace/newline at the very end.
    set data [string trimright $data "\r\n"]


    # Convert each visible text line into an HL7 segment
    # separator.
    #
    # \n -> \r
    set data \
        [string map {
            "\n" "\r"
        } $data]


    return $data
}


puts "============================================================"
puts "READ HL7 FILE"
puts "============================================================"


set inputFile \
    [file join \
        $testDataDir \
        oru_high_k_input.hl7]


set msg [read_hl7_file $inputFile]


puts "File:"
puts $inputFile

puts ""
puts "HL7:"

puts [string map {"\r" "\n"} $msg]


puts ""
puts "============================================================"
puts "FILE INFORMATION"
puts "============================================================"


puts "Exists?"
puts [file exists $inputFile]

puts ""

puts "Is file?"
puts [file isfile $inputFile]

puts ""

puts "Directory:"
puts [file dirname $inputFile]

puts ""

puts "Filename:"
puts [file tail $inputFile]

puts ""

puts "Extension:"
puts [file extension $inputFile]

puts ""

puts "Size:"
puts [file size $inputFile]	


set actual \
    [oru::transform $msg 5.5]


puts ""
puts "============================================================"
puts "ACTUAL OUTPUT"
puts "============================================================"

puts [string map {"\r" "\n"} $actual]

set expectedFile \
    [file join \
        $testDataDir \
        oru_high_k_expected.hl7]


set expected \
    [read_hl7_file $expectedFile]


puts ""
puts "============================================================"
puts "TEST RESULT"
puts "============================================================"


if {$actual eq $expected} {

    puts "PASS"

} else {

    puts "FAIL"
}


proc assert_equal {testName actual expected} {

    if {$actual eq $expected} {

        puts [format \
            "%-40s PASS" \
            $testName]

        return 1
    }


    puts [format \
        "%-40s FAIL" \
        $testName]


    puts ""
    puts "--- EXPECTED ---"
    puts [string map {"\r" "\n"} $expected]

    puts ""
    puts "--- ACTUAL ---"
    puts [string map {"\r" "\n"} $actual]

    puts ""


    return 0
}

assert_equal \
    "ORU high potassium" \
    $actual \
    $expected




proc run_hl7_test {
    testName
    inputFile
    expectedFile
    threshold
} {

    set input \
        [read_hl7_file $inputFile]

    set expected \
        [read_hl7_file $expectedFile]

    set actual \
        [oru::transform $input $threshold]


    return \
        [assert_equal \
            $testName \
            $actual \
            $expected]
}

puts ""
puts "============================================================"
puts "REGRESSION TESTS"
puts "============================================================"


set passed 0
set failed 0


set result \
    [run_hl7_test \
        "ORU high potassium" \
        [file join $testDataDir oru_high_k_input.hl7] \
        [file join $testDataDir oru_high_k_expected.hl7] \
        5.5]


if {$result} {
    incr passed
} else {
    incr failed
}


set result \
    [run_hl7_test \
        "ORU normal potassium" \
        [file join $testDataDir oru_normal_k_input.hl7] \
        [file join $testDataDir oru_normal_k_expected.hl7] \
        5.5]


if {$result} {
    incr passed
} else {
    incr failed
}


puts ""
puts "============================================================"
puts "SUMMARY"
puts "============================================================"

puts "Passed: $passed"
puts "Failed: $failed"


puts ""
puts "============================================================"
puts " glob command "
puts "============================================================"

set files \
    [glob -nocomplain \
        [file join $testDataDir "*_input.hl7"]]


foreach filename $files {

    puts [file tail $filename]

    set basename \
        [file tail $filename]

    set testName \
        [string map {
            "_input.hl7" ""
        } $basename]


    set expectedName \
        [string map {
            "_input.hl7" "_expected.hl7"
        } $basename]


    puts "Test     = $testName"
    puts "Expected = $expectedName" 
}

set elapsed \
    [expr {[clock milliseconds] - $start}]

puts ""
puts "work transformation took $elapsed ms"
