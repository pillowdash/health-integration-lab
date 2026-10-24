# --- Local Cloverleaf Simulator ---

# 02_tps_proc_mem_pointer.tcl
package require Tclx

# --- Local Cloverleaf Simulator ---
global memory_heap
array set memory_heap {}

# Mock HL7 payloads originating from Epic going to a local Orthanc PACS
set memory_heap(mh_001) "MSH|^~\\&|EPIC|ER|ORTHANC|PACS|202610010428||ADT^A04|msg_1|P|2.4\rPID|1||123456^^^MRN||Smith^John\r"
set memory_heap(mh_002) "MSH|^~\\&|EPIC|ER|ORTHANC|PACS|202610010428||ADT^A08|msg_2|P|2.4\rPID|1||789012^^^MRN||Doe^Jane\r"
set memory_heap(mh_003) "MSH|^~\\&|EPIC|ER|ORTHANC|PACS|202610010428||ADT^A31|msg_3|P|2.4\rPID|1||345678^^^MRN||Roe^Richard\r"

proc msgget {mh} {
    global memory_heap
    return $memory_heap($mh)
}

proc msgset {mh data} {
    global memory_heap
    set memory_heap($mh) $data
}

# ------------------------------------------------------------------
# TPS proc called by the (simulated) engine
# ------------------------------------------------------------------
proc tps_filter_adt { args } {
    keylget args MODE mode
    set dispList {}

    switch -exact -- $mode {
        start {
            # Load the filter config once at startup. In real Cloverleaf
            # this comes from the Tcl global set in the proc properties.
            set ::filter_list [split "A04,A31" ","]
            puts "\[START\] tps_filter_adt online - filtering on: $::filter_list"
        }

        run {
            keylget args MSGID mh
            set msg [msgget $mh]

            # ---- Parse the MSH segment ----
            set segs [split $msg "\r"]
            set msh  [lindex $segs 0]
            set f    [split $msh "|"]        ;# | is MSH-1

            set sending_app   [lindex $f 2]  ;# MSH-3
            set receiving_app [lindex $f 4]  ;# MSH-5
            set msg_type      [lindex $f 8]  ;# MSH-9  e.g. ADT^A04

            # Extract the trigger event from ADT^A04 -> A04
            set trigger [lindex [split $msg_type "^"] 1]

            puts "\[RUN \] $mh  $sending_app -> $receiving_app  ($msg_type)"

            if {[lsearch -exact $::filter_list $trigger] >= 0} {
                puts "       MATCH  (trigger=$trigger) -> CONTINUE"
                lappend dispList "CONTINUE $mh"
            } else {
                puts "       SKIP   (trigger=$trigger) -> KILL"
                lappend dispList "KILL $mh"
            }
        }

        time {
            # Periodic timer callback - not used in this demo
        }

        stop {
            puts "\[STOP \] tps_filter_adt shutting down."
        }

        default {
            error "tps_filter_adt: unknown mode '$mode'"
        }
    }

    return $dispList
}

# ------------------------------------------------------------------
# Simulated Cloverleaf engine driver
# ------------------------------------------------------------------
puts "=== Cloverleaf TPS Simulator ==="
puts ""

# 1. Engine brings the proc online (mode=start, no msgid)
tps_filter_adt {MODE start}
puts ""

# 2. Engine dispatches each message handle to the proc
#    Note: [list MSGID $mh] is essential — braces would prevent $mh
#    from being substituted.
foreach mh {mh_001 mh_002 mh_003} {
    set disp [tps_filter_adt {MODE run} [list MSGID $mh]]
    puts "       disposition: $disp"
    puts ""
}

# 3. Engine shuts the proc down
tps_filter_adt {MODE stop}
