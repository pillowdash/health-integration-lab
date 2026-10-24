puts ""
puts "braces - \$x is not substituted before while starts. Instead, while reevaluates the expression each time"
set x 1

# on every iteration. Because it is inside braces, $x is not substituted before while starts. Instead, while reevaluates the expression each time.
# Tcl repeatedly evaluates {$x < 5}
while {$x < 5} {
    puts "x is $x"
    set x [expr {$x + 1}]
}

puts ""
puts "double quotes - Tcl substitutes it immediately"
# the condition uses double quotes, not braces.
# At the moment Tcl executes the while command, $x is currently 0, so Tcl substitutes it immediately:
# "$x < 5" becomes: "0 < 5" which is always true. 
# That means the loop condition no longer changes as x changes.
set x 0

while "$x < 5" {
    set x [expr {$x + 1}]

    if {$x > 7} break
    if {$x > 3} continue

    puts "x is $x"
}
