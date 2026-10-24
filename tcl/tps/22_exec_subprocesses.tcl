puts "============================================================"
puts "1. BASIC EXEC"
puts "============================================================"

set result [exec uname -a]

puts $result

set result [exec whoami]

puts "Current user = $result"

set result [exec date]

puts "OS date = $result"


puts ""
puts "============================================================"
puts "2. GREP HL7"
puts "============================================================"

set filename \
    "tcl/testdata/oru_high_k_input.hl7"

set obxLines \
    [exec grep {^OBX} $filename]

puts $obxLines


set count \
    [exec grep -c {^OBX} $filename]

puts "OBX count = $count"

puts ""
puts "============================================================"
puts "3. EXEC ERROR HANDLING"
puts "============================================================"

set filename \
    "file_that_does_not_exist.hl7"

if {[catch {

    set result \
        [exec cat $filename]

} err options]} {

    puts "External command failed:"
    puts $err


    puts ""
    puts "Options:"
    puts $options    

    if {[dict exists $options -errorcode]} {

	set errorCode \
	    [dict get $options -errorcode]


        puts "Error code:"
        puts $errorCode
	puts "Type = [lindex $errorCode 0]"
	puts "PID  = [lindex $errorCode 1]"
	puts "Exit = [lindex $errorCode 2]"	
    }    
} else {

    puts "External command succeeded:"
    puts $result
}


puts ""
puts "============================================================"
puts "4. OPEN A PIPE"
puts "============================================================"

set pipe \
    [open "|date" r]

set output \
    [read $pipe]

close $pipe

puts "date returned:"
puts $output


set pipe \
    [open "|ps" r]

while {[gets $pipe line] >= 0} {

    puts "PROCESS: $line"
}

close $pipe


puts ""
puts "============================================================"
puts "5. PROCESS STARTUP COST"
puts "============================================================"

set iterations 100

set start \
    [clock milliseconds]

for {set i 0} {$i < $iterations} {incr i} {

    exec true
}

set elapsed \
    [expr {
        [clock milliseconds] - $start
    }]

puts "External process calls = $iterations"
puts "Elapsed                = $elapsed ms"

puts [format \
    "Average                = %.3f ms/call" \
    [expr {$elapsed / double($iterations)}]]


set commands {
    {uname -s}
    {whoami}
    {date}
    {grep -c ^OBX tcl/testdata/oru_high_k_input.hl7}
}

foreach command $commands {

    puts ""
    puts "COMMAND: $command"

    if {[catch {

        set result \
            [exec {*}$command]

    } err]} {

        puts "FAILED: $err"

    } else {

        puts "RESULT: $result"
    }
}
