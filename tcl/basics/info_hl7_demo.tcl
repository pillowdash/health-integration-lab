# ============================================================
# TCL "info" COMMAND DEMO WITH HL7 DATA
# ============================================================

set interfaceName "OLIS_OUT"
set environment "TEST"

set hl7msg \
"MSH|^~\\&|LAB|TSH|EPIC|TSH|202610061100||ORU^R01|MSG1001|P|2.5\rPID|1||123456^^^TSH^MR||SMITH^JOHN\rOBX|1|NM|K^Potassium||5.8|mmol/L|3.5-5.1|H|||F"

#package require Tclx
# keylget --comment out the line above so keylget command available 

# ------------------------------------------------------------
# A procedure with a required argument and an optional argument
# ------------------------------------------------------------

proc processOru {msg {mode NORMAL}} {

    set messageType "ORU"
    set triggerEvent "R01"

    puts ""
    puts "=== INSIDE processOru ==="

    # info exists
    puts "msg exists?         [info exists msg]"
    puts "messageType exists? [info exists messageType]"
    puts "missingVar exists?  [info exists missingVar]"

    # info locals
    puts ""
    puts "Local variables:"
    puts [lsort [info locals]]

    # info globals
    puts ""
    puts "Selected globals:"
    puts [info globals interface*]

    # info level
    puts ""
    puts "Current call level = [info level]"

    # show caller
    if {[info level] > 0} {
        puts "Caller command = [info frame -1]"
    }
}


puts "=== TCL ENVIRONMENT ==="

puts "Tcl version = [info tclversion]"
puts "Patch level = [info patchlevel]"
puts "Executable  = [info nameofexecutable]"
puts "Script      = [info script]"


puts ""
puts "=== VARIABLES ==="

puts "interfaceName exists? [info exists interfaceName]"
puts "hl7msg exists?        [info exists hl7msg]"

puts ""
puts "Global variables matching interface*:"
puts [info globals interface*]


puts ""
puts "=== COMMAND DISCOVERY ==="

puts "regexp exists? [expr {[llength [info commands regexp]] > 0}]"
puts "keylget exists? [expr {[llength [info commands keylget]] > 0}]"
puts "msgget exists?  [expr {[llength [info commands msgget]] > 0}]"


puts ""
puts "=== PROCEDURE DISCOVERY ==="

puts "Our procedures:"
puts [info procs process*]

puts ""
puts "processOru arguments:"
puts [info args processOru]

puts ""
puts "processOru body:"
puts [info body processOru]


puts ""
puts "=== DEFAULT ARGUMENT ==="

set hasDefault \
    [info default processOru mode defaultMode]

puts "mode has default? $hasDefault"
puts "mode default     = $defaultMode"


puts ""
puts "=== CALL PROCEDURE ==="

processOru $hl7msg
