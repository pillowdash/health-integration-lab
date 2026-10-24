
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



puts "============================================================"
puts "1. BASIC catch"
puts "============================================================"

set rc [catch {

    set x 10
    set y 2

    expr {$x / $y}

} result]

puts "catch return code = $rc"
puts "result            = $result"


proc validate_threshold {threshold} {

    if {![string is double -strict $threshold]} {

#        error "Invalid potassium threshold <$threshold>"

        return \
            -code error \
            -errorcode {
                INTERFACE
                CONFIG
                INVALID_THRESHOLD
            } \
            "Invalid potassium threshold <$threshold>"	    
    }

    if {$threshold <= 0} {
        return \
            -code error \
            -errorcode {
                INTERFACE
                CONFIG
                INVALID_THRESHOLD
            } \
            "Potassium threshold must be greater than zero"	    

        #error "Potassium threshold must be greater than zero"
    }

    return $threshold
}

foreach threshold {
    5.5
    ABC
    -1
} {

    puts ""
    puts "Testing threshold <$threshold>"

    if {[catch {

        set result \
            [validate_threshold $threshold]

    } err options]} {

        #puts "FAILED: $err"


	puts "Message:"
	puts $err

	puts ""

	puts "Error code:"
	puts [dict get $options -errorcode]

    } else {

        puts "VALID: $result"
    }
}


proc level3 {} {

    error "Something failed in level3"
}


proc level2 {} {

    level3
}


proc level1 {} {

    level2
}


if {[catch {

    level1

} err]} {

    puts "Caught:"
    puts $err
}


puts ""
puts "============================================================"
puts "2. ERROR DETAILS"
puts "============================================================"

if {[catch {

    level1

} err options]} {

    puts "ERROR MESSAGE:"
    puts $err

    puts ""

    puts "ERROR CODE:"
    puts [dict get $options -errorcode]

    puts ""

    puts "STACK TRACE:"
    puts [dict get $options -errorinfo]
}


puts ""
puts "============================================================"
puts "3. TRY"
puts "============================================================"

try {

    set threshold ABC

    validate_threshold $threshold

} on error {err options} {

    puts "Caught by try:"
    puts $err

} finally {

    puts "finally always executes"
}


proc process_oru_message {msg threshold} {

    # --------------------------------------------
    # Validate configuration
    # --------------------------------------------

    if {![string is double -strict $threshold]} {

        return \
            -code error \
            -errorcode {
                INTERFACE
                CONFIG
                INVALID_THRESHOLD
            } \
            "Invalid potassium threshold <$threshold>"
    }


    # --------------------------------------------
    # Validate HL7 type
    # --------------------------------------------

    set typeInfo \
        [hl7::get_message_type_components $msg]

    set messageCode \
        [dict get $typeInfo messageCode]

    set triggerEvent \
        [dict get $typeInfo triggerEvent]


    if {$messageCode ne "ORU" ||
        $triggerEvent ne "R01"} {

        return \
            -code error \
            -errorcode {
                HL7
                MESSAGE_TYPE
                UNEXPECTED
            } \
            "Expected ORU^R01; received $messageCode^$triggerEvent"
    }


    # --------------------------------------------
    # Transform
    # --------------------------------------------

    return \
        [oru::transform \
            $msg \
            $threshold]
}


if {[catch {

    set transformed \
        [process_oru_message \
            $msg \
            5.5]

} err options]} {

    puts "PROCESSING FAILED"

    puts "Error:"
    puts $err

    puts "Code:"
    puts [dict get $options -errorcode]

} else {

    puts "PROCESSING SUCCEEDED"
}


proc safe_process_oru {
    msg
    threshold
} {

    # ------------------------------------------------
    # First decide whether this message applies
    # ------------------------------------------------

    set typeInfo \
        [hl7::get_message_type_components $msg]

    set messageCode \
        [dict get $typeInfo messageCode]

    set triggerEvent \
        [dict get $typeInfo triggerEvent]


    if {$messageCode ne "ORU" ||
        $triggerEvent ne "R01"} {

        return [dict create \
            disposition CONTINUE \
            message $msg \
            reason "Not ORU^R01"]
    }


    # ------------------------------------------------
    # Then perform processing with error protection
    # ------------------------------------------------

    if {[catch {

        if {![string is double -strict $threshold]} {

            return \
                -code error \
                -errorcode {
                    INTERFACE
                    CONFIG
                    INVALID_THRESHOLD
                } \
                "Invalid threshold <$threshold>"
        }


        set transformed \
            [oru::transform \
                $msg \
                $threshold]


    } err options]} {

        return [dict create \
            disposition ERROR \
            message $msg \
            error $err \
            errorCode \
                [dict get $options -errorcode] \
            errorInfo \
                [dict get $options -errorinfo]]
    }


    return [dict create \
        disposition CONTINUE \
        message $transformed \
        reason "Transformation successful"]
}


# ============================================================
# READ A FILE
# ============================================================

proc read_text_file {filename} {

    set fp [open $filename r]

    set data [read $fp]

    close $fp

    return $data
}



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



set inputFile \
    [file join \
        $testDataDir \
        oru_high_k_input.hl7]


set msg [read_hl7_file $inputFile]


set result \
    [safe_process_oru \
        $msg \
        5.5]


puts "Disposition:"
puts [dict get $result disposition]


puts "Reason:"
puts [dict get $result reason]


set result \
    [safe_process_oru \
        $msg \
        ABC]

puts [dict get $result disposition]
puts [dict get $result error]
