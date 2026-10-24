# Even for is just a Tcl command, and a command can be replaced by another command with the same name.

# Tcl does not have a large distinction between
# "language syntax" and "commands"
# the way Java/C#/JavaScript do.

# A huge amount of Tcl is:

# command argument argument argument...

proc for {a b c} {
    puts "The for command has been replaced by a puts with 3 arguments";
    puts "The arguments were: \nargument 1 =$a\nargument 2 =$b\nargument 3 =$c\n"
}

for {set i 1} {$i < 10} {incr i}


puts ""
puts "Tcl does not go back and substitute \$i again.\
Tcl substitution is not recursively repeated. see blow"
puts ""

proc for {a b c d} {
    puts "The for command has been replaced by a puts with 4 arguments";
    puts "The arguments were: \nargument 1 =$a\nargument 2 =$b\nargument 3 =$c\nargument 4 =$d\n"
}

for {set i 1} {$i < 10} {incr i} {

	puts "$i"
}
