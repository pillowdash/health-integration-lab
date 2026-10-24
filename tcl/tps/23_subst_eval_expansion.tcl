puts "============================================================"
puts "1. SUBST"
puts "============================================================"

set patientName "SMITH^JOHN"
set mrn "123456"

set template {
Patient = $patientName
MRN     = $mrn
}

puts "Before subst:"
puts $template

puts ""
puts "After subst:"
puts [subst $template]


set template {
Current time = [clock format [clock seconds] -format "%Y-%m-%d %H:%M:%S"]
}

puts ""
puts $template
puts "After subst:"
puts [subst $template]


set controlId "MSG23001"
set interface "LAB_OUT"
set disposition "CONTINUE"

set logTemplate {
interface=$interface controlId=$controlId disposition=$disposition
}

set logLine [subst $logTemplate]

puts $logLine


set x "puts HELLO"

puts "x = <$x>"

set result [subst $x]

puts "result = <$result>"


puts ""
puts "============================================================"
puts "2. EVAL"
puts "============================================================"

set command {
    puts "HELLO FROM EVAL"
}

eval $command

set command \
    [list puts "Hello from modern Tcl"]

{*}$command


proc process_message {msg threshold debug} {

    puts "Message   = $msg"
    puts "Threshold = $threshold"
    puts "Debug     = $debug"
}

set arguments \
    [list \
        "ORU^R01 MESSAGE" \
        5.5 \
        1]

process_message {*}$arguments
