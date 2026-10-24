#!/usr/bin/env tclsh
# =====================================================================
# TCL: The Tool Command Language - LISP for the Masses
# Consolidated Demonstrations of Tcl's Homoiconic & Dynamic Features
# =====================================================================

puts "================================================="
puts " 1. BASIC SYNTAX: EVERYTHING IS A COMMAND"
puts "================================================="
# In Tcl, there are no keywords or distinct syntax structures for assignment.
# 'set', 'puts', and 'expr' are all just commands receiving arguments.

set name "Tcl Hacker"
puts "Hello, $name!"

# Math is done via the 'expr' command. 
# Best practice: always wrap math in curly braces to prevent double-substitution.
set result [expr {10 + (5 * 3)}]
puts "10 + (5 * 3) = $result"


puts "\n================================================="
puts " 2. LISTS: THE S-EXPRESSIONS OF TCL"
puts "================================================="
# Like Lisp, Tcl heavily relies on lists. Under the hood, a list is just 
# a carefully formatted string, and code blocks are just lists of lists.

set my_list [list apple banana orange]
lappend my_list "grape"
puts "My list: $my_list"
puts "The second item is: [lindex $my_list 1]"


puts "\n================================================="
puts " 3. PROCEDURES (Functions)"
puts "================================================="
# 'proc' is a command that takes three arguments: 
# Name, List of Arguments, and the Code Block.

proc greet {person} {
    return "Welcome to the system, $person!"
}

puts [greet $name]

#R: MANIPULATING THE CALLER's SCOPE"
puts "================================================="
# upvar allows you to link a local variable to a variable in a higher stack frame.
# This is how Tcl achieves "pass-by-reference" without pointers.

proc increment_by_two {varName} {
    # Link local 'var' to whatever variable name was passed in from level 1 (the caller)
    upvar 1 $varName var

    # Increment the variable directly
    incr var 2
}

set counter 10
puts "Counter before upvar: $counter"
increment_by_two counter
puts "Counter after upvar: $counter"


puts "\n================================================="
puts " 5. CODE AS DATA: EVAL"
puts "================================================="
# Homoiconicity: Because commands are just strings/lists, you can build
# code dynamically as data, and then execute it using 'eval'.

set dynamic_command [list puts "This was executed from a dynamically built list!"]
puts "The raw data looks like: $dynamic_command"
eval $dynamic_command


puts "\n================================================="
puts " 6. UPLEVEL: BUILDING CUSTOM CONTROL STRUCTURES"
puts "================================================="
# This is where Tcl truly mirrors Lisp macros.
# Because code blocks are just strings (in curly braces), you can pass a block
# of code into a proc, and use 'uplevel' to evaluate it in the caller's context.
#
# Let's invent a completely new control structure called 'do_twice'

proc do_twice {code_block} {
    # Evaluate the code block in the caller's stack frame (level 1)
    uplevel 1 $code_block
    uplevel 1 $code_block
}

# Now we use our custom control structure just like a built-in command:
do_twice {
    puts "--> This is running inside our custom do_twice structure!"
}


puts "\n================================================="
puts " 7. COMBINING IT ALL: INVENTING A 'REPEAT ... UNTIL'"
puts "================================================="
# Tcl has 'while', but no 'repeat...until'. Let's build one using uplevel and expr!

proc repeat {code_block until condition} {
    if {$until ne "until"} {
        error "Syntax error: must be 'repeat {code} until {condition}'"
    }

    # Run the code at least once
    uplevel 1 $code_block

    # Keep evaluating the condition in the caller's scope, and loop if false
    while {![uplevel 1 [list expr $condition]]} {
        uplevel 1 $code_block
    }
}

set x 0
repeat {
    puts "Looping: x is $x"
    incr x
} until {$x >= 3}

puts "Done! Tcl allows you to mold the language to your needs."
 
