package require Tclx

# --- Local Cloverleaf Simulator Setup ---
global memory_heap

# Test Case 1: ADT^A31 missing PV1-2
set memory_heap(mh_test_1) "MSH|^~\\&|EPIC|ER|ORTHANC|PACS|20261001||ADT^A31|msg_1|P|2.4\rPID|1||123^^^MRN||Smith^John\rPV1|1||Location\r"

# Test Case 2: ADT^A31 missing PV1 completely
set memory_heap(mh_test_2) "MSH|^~\\&|EPIC|ER|ORTHANC|PACS|20261001||ADT^A31|msg_2|P|2.4\rPID|1||123^^^MRN||Smith^John\r"

# Test Case 3: ADT^A04 (Should pass through untouched)
set memory_heap(mh_test_3) "MSH|^~\\&|EPIC|ER|ORTHANC|PACS|20261001||ADT^A04|msg_3|P|2.4\rPID|1||123^^^MRN||Smith^John\rPV1|1|I|Location\r"

proc msgget {mh} { global memory_heap; return $memory_heap($mh) }
proc msgset {mh data} { global memory_heap; set memory_heap($mh) $data }

# --- The TPS Script ---
proc tps_fix_pv1 { args } {
    keylget args MODE mode
    set dispList {}

    switch -exact -- $mode {
        start {
            # Engine startup - nothing to initialize here
        }
        run {
            keylget args MSGID mh
            set msg [msgget $mh]
            
            # Dynamically grab the field separator (usually |)
            set fld_sep [string index $msg 3]
            set segments [split $msg "\r"]
            
            # 1. Check Message Type in MSH-9 (Index 8)
            set msh_seg [lindex $segments 0]
            set msh_fields [split $msh_seg $fld_sep]
            set msg_type [lindex $msh_fields 8]
            
            if {$msg_type eq "ADT^A31"} {
                # 2. Check for PV1 segment using regex
                set pv1_idx [lsearch -regexp $segments {^PV1}]
                
                if {$pv1_idx == -1} {
                    # 3. Missing PV1 entirely -> KILL the message
                    lappend dispList "KILL $mh"
                } else {
                    # 4. PV1 exists, inspect PV1-2 (Index 2)
                    set pv1_seg [lindex $segments $pv1_idx]
                    set pv1_fields [split $pv1_seg $fld_sep]
                    
                    set pv1_2 [lindex $pv1_fields 2]
                    
                    if {$pv1_2 eq ""} {
                        # Field is empty. Set it to "U"
                        set pv1_fields [lreplace $pv1_fields 2 2 "U"]
                        
                        # Rejoin the PV1 fields
                        set new_pv1_seg [join $pv1_fields $fld_sep]
                        
                        # Replace the old PV1 segment in the master segment list
                        set segments [lreplace $segments $pv1_idx $pv1_idx $new_pv1_seg]
                        
                        # Reassemble the entire message
                        set new_msg [join $segments "\r"]
                        msgset $mh $new_msg
                    }
                    
                    # Continue the modified (or already valid) message
                    lappend dispList "CONTINUE $mh"
                }
            } else {
                # Not an A31, pass it through
                lappend dispList "CONTINUE $mh"
            }
        }
    }
    return $dispList
}

# --- Execution & Verification ---
puts "Running Test 1 (Missing PV1-2)..."
set result1 [tps_fix_pv1 {MODE run} [list MSGID mh_test_1]]
puts "Disposition: $result1"
puts "Resulting Message:\n[string map {\r \n} [msgget mh_test_1]]"

puts "\nRunning Test 2 (Missing PV1 completely)..."
set result2 [tps_fix_pv1 {MODE run} [list MSGID mh_test_2]]
puts "Disposition: $result2"

puts "\nRunning Test 3 (ADT^A04 - bypass logic)..."
set result3 [tps_fix_pv1 {MODE run} [list MSGID mh_test_3]]
puts "Disposition: $result3"
