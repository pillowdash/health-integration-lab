proc who {} {
     set fp [open "|who"]
     while {[gets $fp line] > 0} {
        puts stdout $line 
     }
     close $fp
}

who


proc who {} {
	foreach line [split [exec who] "\n" ] {
	   puts stdout $line
	}
}
who
