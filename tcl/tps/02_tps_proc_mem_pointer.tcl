# --- Local Cloverleaf Simulator ---
global memory_heap
# Mocking an HL7 payload originating from Epic going to a local Orthanc PACS
set memory_heap(mh_001) "MSH|^~\\&|EPIC|ER|ORTHANC|PACS|202610010428||ADT^A04|msg_1|P|2.4\rPID|1||123456^^^MRN||Smith^John\r"

proc msgget {mh} {
    global memory_heap
    return $memory_heap($mh)
}

proc msgset {mh data} {
    global memory_heap
    set memory_heap($mh) $data
}

proc tps_filter_adt { args } {
    keylget args MODE mode
    set dispList {} ;# The disposition list returned to the engine

    switch -exact -- $mode {
        start {
            # Engine startup logic goes here
        }
        run {
            keylget args MSGID mh
            set msg [msgget $mh]

            # ... perform HL7 logic here ...

            # Tell the engine what to do: CONTINUE, KILL, or ERROR
            lappend dispList "CONTINUE $mh"
        }
    }
    return $dispList
}
