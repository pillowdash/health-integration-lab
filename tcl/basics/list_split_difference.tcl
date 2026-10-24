# ============================================================
# DEMO: list versus split
# ============================================================

# list
# → construct a Tcl list from already-separated Tcl arguments

# split
# → take one string and cut it wherever a delimiter occurs

puts "=== Using list ==="

# Here are four already-separated arguments. Make them four list elements.
set b [list a b {c d e} {f {g h}}]

puts "b = $b"
puts "llength = [llength $b]"

puts "index 0 = [lindex $b 0]"
puts "index 1 = [lindex $b 1]"
puts "index 2 = [lindex $b 2]"
puts "index 3 = [lindex $b 3]"


puts ""
puts "=== Using split ==="
puts "=== the default separator being whitespace ==="

# the default separator being whitespace
# split does not understand Tcl grouping braces inside the string.
# braces inside a string have no grouping power when split processes that string.
#
# Here is one string. Cut it wherever whitespace occurs.
set b [split "a b {c d e} {f {g h}}"]

puts "b = $b"
puts "llength = [llength $b]"

puts "index 0 = [lindex $b 0]"
puts "index 1 = [lindex $b 1]"
puts "index 2 = [lindex $b 2]"
puts "index 3 = [lindex $b 3]"
puts "index 4 = [lindex $b 4]"
puts "index 5 = [lindex $b 5]"
puts "index 6 = [lindex $b 6]"
puts "index 7 = [lindex $b 7]"


set pid "PID|1||123456^^^TSH^MR||SMITH^JOHN"

set fields [split $pid "|"]



