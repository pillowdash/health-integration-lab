# A Tcl array is not a first-class value, so you cannot directly return an array variable itself the way you can return a dict.
# array itself
# → cannot be returned as an array value

# array get
# → converts array into a normal Tcl list
# → can be returned

# upvar
# → lets a procedure directly access/modify caller's array

proc make_patient {} {
    array set patient {
        mrn 123456
        name SMITH^JOHN
    }

    # serialize an array into a normal Tcl value
    #
    return [array get patient]
    #
    # try both below:
    # return patient
    # return $patient
}

set data [make_patient]

# reconstruct it from list to array
array set p $data

puts $p(mrn)

puts ""
puts "direct access to a caller's array, upvar is the normal technique"


proc fill_patient {arrayName} {
	
    # create a local alias called patient that refers to the caller's array.
    upvar 1 $arrayName patient

    set patient(mrn) 123456
    set patient(name) SMITH^JOHN
}

array set p {}

fill_patient p

puts $p(mrn)
puts $p(name)

proc show_patient {arrayName} {

    upvar 1 $arrayName patient

    puts "MRN = $patient(mrn)"
    puts "Name = $patient(name)"
}

array set p {
    mrn 875356
    name DOE^JOHN
}

show_patient p

puts ""
puts "create several elements at once with 'array set'"
array set patient {
    mrn      123456
    name     SMITH^JOHN
    facility TSH
    sex      M
}

puts [array names patient]
foreach key [array names patient] {
    puts "$key = $patient($key)"
}
