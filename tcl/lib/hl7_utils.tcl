namespace eval hl7 {

    # ============================================================
    # Parse a simple HL7 path.
    #
    # Supported:
    #   PID-3
    #   PID-3.1
    #   MSH-9.2
    #   OBR-4.1
    #   OBX-5
    #
    # Returns:
    #   segment   PID
    #   field     3
    #   component 1
    #
    # If no component is specified:
    #   component ""
    # ============================================================
    proc parse_path {path} {

        if {![regexp -expanded {
            ^                       # beginning of path

            ([A-Z0-9]{3})           # capture 1: segment name

            -                       # literal hyphen

            ([0-9]+)                # capture 2: field number

            (?:                     # optional component section
                \.                  # literal dot
                ([0-9]+)            # capture 3: component number
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


    # ============================================================
    # Return the segment name from one raw HL7 segment.
    # ============================================================
    proc segment_name {segment} {
        return [lindex [split $segment "|"] 0]
    }


    # ============================================================
    # Return the first segment of the requested type.
    # ============================================================
    proc get_segment {msg segmentName} {

        foreach segment [split $msg "\r"] {

            if {[hl7::segment_name $segment] eq $segmentName} {
                return $segment
            }
        }

        return ""
    }


    # ============================================================
    # Return all segments of the requested type.
    # ============================================================
    proc get_segments {msg segmentName} {

        set matches {}

        foreach segment [split $msg "\r"] {

            if {[hl7::segment_name $segment] eq $segmentName} {
                lappend matches $segment
            }
        }

        return $matches
    }


    # ============================================================
    # Return the Nth occurrence of a segment.
    #
    # Human-friendly numbering:
    #   occurrence 1 = first segment
    #   occurrence 2 = second segment
    # ============================================================
    proc get_segment_n {msg segmentName occurrence} {

        set segments [hl7::get_segments $msg $segmentName]

        set index [expr {$occurrence - 1}]

        if {$index < 0 || $index >= [llength $segments]} {
            return ""
        }

        return [lindex $segments $index]
    }


    # ============================================================
    # Read a field/component from ONE known segment.
    #
    # Examples:
    #   hl7::get_from_segment $pid "PID-3"
    #   hl7::get_from_segment $obx "OBX-3.1"
    # ============================================================
    proc get_from_segment {segment path} {

        set parsed [hl7::parse_path $path]

        set expectedSegment [dict get $parsed segment]
        set fieldNumber     [dict get $parsed field]
        set componentNumber [dict get $parsed component]

        set actualSegment [hl7::segment_name $segment]

        if {$actualSegment ne $expectedSegment} {
            error "Expected $expectedSegment segment but received $actualSegment"
        }

        set fields [split $segment "|"]

        # MSH is special because MSH-1 is the field separator itself.
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

        set components [split $fieldValue "^"]

        set componentIndex [expr {$componentNumber - 1}]

        if {$componentIndex < 0 || $componentIndex >= [llength $components]} {
            return ""
        }

        return [lindex $components $componentIndex]
    }


    # ============================================================
    # Modify a field/component in ONE known segment.
    # ============================================================
    proc set_in_segment {segment path newValue} {

        set parsed [hl7::parse_path $path]

        set expectedSegment [dict get $parsed segment]
        set fieldNumber     [dict get $parsed field]
        set componentNumber [dict get $parsed component]

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

        # Extend fields when the requested field is not present yet.
        while {[llength $fields] <= $fieldIndex} {
            lappend fields ""
        }

        # Whole field replacement.
        if {$componentNumber eq ""} {

            lset fields $fieldIndex $newValue

            return [join $fields "|"]
        }

        # Component replacement.
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


    # ============================================================
    # Read from the first matching segment in a full message.
    #
    # get() no longer contains its own field/component parser.
    # parse_path + get_segment + get_from_segment do the work.
    # ============================================================
    proc get {msg path} {

        set parsed [hl7::parse_path $path]
        set segmentName [dict get $parsed segment]

        set segment [hl7::get_segment $msg $segmentName]

        if {$segment eq ""} {
            return ""
        }

        return [hl7::get_from_segment $segment $path]
    }


    # ============================================================
    # Modify the first matching segment in a full message.
    #
    # set_field() delegates the actual HL7 field/component
    # modification to set_in_segment().
    # ============================================================
    proc set_field {msg path newValue} {

        set parsed [hl7::parse_path $path]
        set segmentName [dict get $parsed segment]

        set newSegments {}
        set found 0

        foreach segment [split $msg "\r"] {

            if {!$found &&
                [hl7::segment_name $segment] eq $segmentName} {

                set segment \
                    [hl7::set_in_segment $segment $path $newValue]

                set found 1
            }

            lappend newSegments $segment
        }

        return [join $newSegments "\r"]
    }


    # ============================================================
    # Return the requested field/component from every matching
    # segment.
    #
    # Example:
    #   hl7::get_all $msg "OBX-5"
    # ============================================================
    proc get_all {msg path} {

        set parsed [hl7::parse_path $path]
        set segmentName [dict get $parsed segment]

        set values {}

        foreach segment [hl7::get_segments $msg $segmentName] {
            lappend values [hl7::get_from_segment $segment $path]
        }

        return $values
    }


    # ============================================================
    # Return repetitions of the first matching field.
    #
    # Example:
    #   PID-3 repetition separator = ~
    # ============================================================
    proc get_repetitions {msg path} {

        set value [hl7::get $msg $path]

        if {$value eq ""} {
            return {}
        }

        return [split $value "~"]
    }


    # ============================================================
    # Convenience helpers built on top of get().
    # ============================================================
    proc get_message_control_id {msg} {

        set msh [hl7::get_segment $msg MSH]

        if {$msh eq ""} {
            return "UNKNOWN"
        }

        return [hl7::get_from_segment $msh "MSH-10"]
    }


    proc get_message_type {msg} {
        return [hl7::get $msg "MSH-9"]
    }


    proc get_message_type_components {msg} {

        return [dict create \
            messageCode  [hl7::get $msg "MSH-9.1"] \
            triggerEvent [hl7::get $msg "MSH-9.2"]]
    }
}

package provide hl7utils 1.1
