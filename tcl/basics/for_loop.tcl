# make sure the starting brace '{' at the same line as 'for' command#
#
# Tcl's syntax is
# for {initialization} {condition} {next-step} {
#    body
# }
# {set i 0}    → run once before the loop
# {$i < 10}    → check before each iteration
# {incr i}     → run after each iteration
# {puts ...}   → loop body
for {set i 0} {$i < 10} {incr i} {
    puts "I inside first loop: $i"
}
puts $i


# One Tcl syntax detail here is very important:
# set i 0
# incr i

# use i, not $i, because these commands want the variable name.
# But:
# $i < 10
# puts "$i"
#
#
# How about this :
# puts i

# use $i because you want the value stored in i.
# So:
# i   → variable name
# $i  → value of variable

puts ""
puts "the 2nd loop"

#
# make sure the starting brace '{' at the same line as 'for' command#
#
# A for loop checks its condition before executing the body.
for {set i 3} {$i < 2} {incr i} { 
    puts "I inside second loop: $i"
}
# for this loop, {next-step} never reach 
puts "for the 2nd loop, {next-step} never happen, therefore i is still the initial value"
puts $i
puts i
