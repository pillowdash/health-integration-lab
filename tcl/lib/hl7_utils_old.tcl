namespace eval hl7 {

	proc parse_path {path} {

	    # --------------------------------------------------------
	    # Supported paths:
	    #
	    #   PID-3
	    #   PID-3.1
	    #   MSH-9.2
	    #   OBR-4.1
	    #   OBX-5
	    #
	    # Returned dictionary:
	    #
	    #   segment   PID
	    #   field     3
	    #   component 1
	    #
	    # If no component is specified:
	    #
	    #   component ""
	    # --------------------------------------------------------

	    if {![regexp -expanded {
		^                       # beginning of path

		([A-Z0-9]{3})           # capture 1:
					# HL7 segment name

		-                       # literal hyphen

		([0-9]+)                # capture 2:
					# HL7 field number

		(?:                     # non-capturing optional group

		    \.                  # literal dot

		    ([0-9]+)            # capture 3:
					# component number

		)?

		$                       # end of path

	    } $path fullMatch segmentName fieldNumber componentNumber]} {

		error "Invalid HL7 path: $path"
	    }


	    return [dict create \
		segment   $segmentName \
		field     $fieldNumber \
		component $componentNumber]
	}	

    proc get_message_control_id {msg} {

        set segments [split $msg "\r"]

        foreach segment $segments {

            set fields [split $segment "|"]

            if {[lindex $fields 0] eq "MSH"} {

                # MSH-10 -> Tcl index 9
                return [lindex $fields 9]
            }
        }

        return "UNKNOWN"
    }


    proc get_message_type {msg} {

        set segments [split $msg "\r"]

        foreach segment $segments {

            set fields [split $segment "|"]

            if {[lindex $fields 0] eq "MSH"} {

                # MSH-9 -> Tcl index 8
                return [lindex $fields 8]
            }
        }

        return ""
    }

    proc get_message_type_components {msg} {

        set messageType [hl7::get_message_type $msg]

        set components [split $messageType "^"]

        return [dict create \
            messageCode [lindex $components 0] \
            triggerEvent [lindex $components 1]]
    }

    proc get_segment {msg segmentName} {

         set segments [split $msg "\r"]

         foreach segment $segments {

             set fields [split $segment "|"]

             if {[lindex $fields 0] eq $segmentName} {
                 return $segment
             }
          }

          return ""
    }

    proc get {msg path} {

	# Examples:
	# PID-3
	# PID-3.1
	# OBX-5
	# MSH-9.2

	if {![regexp {^([A-Z0-9]{3})-([0-9]+)(?:\.([0-9]+))?$} \
	    $path -> segmentName fieldNumber componentNumber]} {

	error "Invalid HL7 path: $path"
	}

	set segment [hl7::get_segment $msg $segmentName]

	if {$segment eq ""} {
	return ""
	}

	set fields [split $segment "|"]

	#
	# MSH is special because MSH-1 is the field separator itself.
	#
	if {$segmentName eq "MSH"} {

	if {$fieldNumber == 1} {
	    return "|"
	}

	set fieldIndex [expr {$fieldNumber - 1}]

	} else {

	set fieldIndex $fieldNumber
	}

	set fieldValue [lindex $fields $fieldIndex]

	#
	# Caller only asked for the field
	#
	if {$componentNumber eq ""} {
	return $fieldValue
	}

	set components [split $fieldValue "^"]

	set componentIndex [expr {$componentNumber - 1}]

	return [lindex $components $componentIndex]
    }

	proc set_field {msg path newValue} {

	    if {![regexp {^([A-Z0-9]{3})-([0-9]+)(?:\.([0-9]+))?$} \
		    $path -> segmentName fieldNumber componentNumber]} {

		error "Invalid HL7 path: $path"
	    }

	    set segments [split $msg "\r"]
	    set newSegments {}

	    set found 0

	    foreach segment $segments {

		set fields [split $segment "|"]

		if {[lindex $fields 0] eq $segmentName && !$found} {

		    set found 1

		    if {$segmentName eq "MSH"} {

			if {$fieldNumber == 1} {
			    error "Changing MSH-1 is not supported yet"
			}

			set fieldIndex [expr {$fieldNumber - 1}]

		    } else {

			set fieldIndex $fieldNumber
		    }

		    #
		    # Whole field replacement
		    #
		    if {$componentNumber eq ""} {

			lset fields $fieldIndex $newValue

		    } else {

			#
			# Component replacement
			#
			set fieldValue [lindex $fields $fieldIndex]

			set components [split $fieldValue "^"]

			set componentIndex [expr {$componentNumber - 1}]

			#
			# Extend the component list if necessary
			#
			while {[llength $components] <= $componentIndex} {
			    lappend components ""
			}

			lset components $componentIndex $newValue

			lset fields $fieldIndex [join $components "^"]
		    }

		    set segment [join $fields "|"]
		}

		lappend newSegments $segment
	    }

	    return [join $newSegments "\r"]
	}    
	

	proc get_segments {msg segmentName} {

	    set matches {}

	    set segments [split $msg "\r"]

	    foreach segment $segments {

		set fields [split $segment "|"]

		if {[lindex $fields 0] eq $segmentName} {
		    lappend matches $segment
		}
	    }

	    return $matches
	}	

	proc get_segment_n {msg segmentName occurrence} {

	    set segments [hl7::get_segments $msg $segmentName]

	    # We use human-friendly numbering:
	    #
	    # occurrence 1 = first segment
	    # occurrence 2 = second segment
	    #
	    # Tcl list index therefore = occurrence - 1

	    set index [expr {$occurrence - 1}]

	    if {$index < 0 || $index >= [llength $segments]} {
		return ""
	    }

	    return [lindex $segments $index]
	}

	proc get_all {msg path} {

	    if {![regexp {^([A-Z0-9]{3})-([0-9]+)(?:\.([0-9]+))?$} \
		    $path -> segmentName fieldNumber componentNumber]} {

		error "Invalid HL7 path: $path"
	    }

	    set matchingSegments [hl7::get_segments $msg $segmentName]

	    set values {}

	    foreach segment $matchingSegments {

		set fields [split $segment "|"]

		if {$segmentName eq "MSH"} {

		    if {$fieldNumber == 1} {
			set fieldValue "|"
		    } else {
			set fieldIndex [expr {$fieldNumber - 1}]
			set fieldValue [lindex $fields $fieldIndex]
		    }

		} else {

		    set fieldValue [lindex $fields $fieldNumber]
		}

		if {$componentNumber ne ""} {

		    set components [split $fieldValue "^"]

		    set componentIndex [expr {$componentNumber - 1}]

		    set fieldValue [lindex $components $componentIndex]
		}

		lappend values $fieldValue
	    }

	    return $values
	}

	proc get_repetitions {msg path} {

	    set value [hl7::get $msg $path]

	    if {$value eq ""} {
		return {}
	    }

	    return [split $value "~"]
	}	


	proc segment_name {segment} {

	    return [lindex [split $segment "|"] 0]
	}


	proc get_from_segment {segment path} {

	    # --------------------------------------------------------
	    # Parse:
	    #
	    #   OBX-3.1
	    #
	    # into:
	    #
	    #   segment   OBX
	    #   field     3
	    #   component 1
	    # --------------------------------------------------------

	    set parsed [hl7::parse_path $path]

	    set expectedSegment [dict get $parsed segment]
	    set fieldNumber     [dict get $parsed field]
	    set componentNumber [dict get $parsed component]


	    # --------------------------------------------------------
	    # Verify that the supplied segment actually matches
	    # the segment specified by the path.
	    # --------------------------------------------------------

	    set actualSegment [hl7::segment_name $segment]

	    if {$actualSegment ne $expectedSegment} {

		error \
		    "Expected $expectedSegment segment but received $actualSegment"
	    }


	    set fields [split $segment "|"]


	    # --------------------------------------------------------
	    # MSH requires special indexing.
	    #
	    # Normal segment:
	    #
	    #   PID-3 -> Tcl index 3
	    #
	    # MSH:
	    #
	    #   MSH-1 is |
	    #   MSH-2 is Tcl index 1
	    #   MSH-9 is Tcl index 8
	    # --------------------------------------------------------

	    if {$expectedSegment eq "MSH"} {

		if {$fieldNumber == 1} {
		    return "|"
		}

		set fieldIndex [expr {$fieldNumber - 1}]

	    } else {

		set fieldIndex $fieldNumber
	    }


	    if {$fieldIndex >= [llength $fields]} {
		return ""
	    }


	    set fieldValue [lindex $fields $fieldIndex]


	    # Whole field requested.
	    if {$componentNumber eq ""} {
		return $fieldValue
	    }


	    # Component requested.
	    set components [split $fieldValue "^"]

	    set componentIndex \
		[expr {$componentNumber - 1}]


	    if {$componentIndex >= [llength $components]} {
		return ""
	    }


	    return [lindex $components $componentIndex]
	}


	proc set_in_segment {segment path newValue} {

	    #if {![regexp {^([A-Z0-9]{3})-([0-9]+)(?:\.([0-9]+))?$} $path -> expectedSegment fieldNumber componentNumber]} {

	     #   error "Invalid HL7 path: $path"
	    #}

		if {![regexp -expanded {
		    ^                       # beginning
		    ([A-Z0-9]{3})           # segment name
		    -
		    ([0-9]+)                # field number
		    (?: \. ([0-9]+) )?      # optional component
		    $                       # end
		} $path -> expectedSegment fieldNumber componentNumber]} {

		    error "Invalid HL7 path: $path"
		}	

	    set actualSegment [hl7::segment_name $segment]

	    if {$actualSegment ne $expectedSegment} {
		error "Expected $expectedSegment segment but received $actualSegment"
	    }


	    set fields [split $segment "|"]


	    if {$expectedSegment eq "MSH"} {

		if {$fieldNumber == 1} {
		    error "Changing MSH-1 is not supported by this helper"
		}

		set fieldIndex [expr {$fieldNumber - 1}]

	    } else {

		set fieldIndex $fieldNumber
	    }


	    # Make sure enough fields exist.
	    while {[llength $fields] <= $fieldIndex} {
		lappend fields ""
	    }


	    # --------------------------------------------------------
	    # Whole field
	    # --------------------------------------------------------

	    if {$componentNumber eq ""} {

		lset fields $fieldIndex $newValue

		return [join $fields "|"]
	    }


	    # --------------------------------------------------------
	    # Component
	    # --------------------------------------------------------

	    set fieldValue [lindex $fields $fieldIndex]

	    set components [split $fieldValue "^"]

	    set componentIndex [expr {$componentNumber - 1}]


	    while {[llength $components] <= $componentIndex} {
		lappend components ""
	    }


	    lset components $componentIndex $newValue

	    lset fields $fieldIndex [join $components "^"]

	    return [join $fields "|"]
	}



}

package provide hl7utils 1.0
