# ============================================================
# Minimal Cloverleaf runtime simulator for local Tcl testing
# ============================================================

package require Tclx

# Simulated Cloverleaf message store.
#
# Key:
#   message handle such as mh_1001
#
# Value:
#   actual HL7 message
#
array set ::mockMessageStore {}


# ------------------------------------------------------------
# Simulated Cloverleaf msgget
#
# Real Cloverleaf:
#
#     set msg [msgget $mh]
#
# Our local version simply retrieves the HL7 string from
# an associative array.
# ------------------------------------------------------------
proc msgget {mh} {

    if {![info exists ::mockMessageStore($mh)]} {
        error "Mock message handle <$mh> does not exist"
    }

    return $::mockMessageStore($mh)
}


# ------------------------------------------------------------
# Simulated Cloverleaf msgset
#
# Real Cloverleaf:
#
#     msgset $mh $newMsg
#
# Our local version overwrites the HL7 payload stored for
# that mock message handle.
# ------------------------------------------------------------
proc msgset {mh newMsg} {

    set ::mockMessageStore($mh) $newMsg

    return
}


# ------------------------------------------------------------
# Helper to create a fake Cloverleaf message handle
# ------------------------------------------------------------
proc mock_create_message {mh hl7msg} {

    set ::mockMessageStore($mh) $hl7msg
}


# ------------------------------------------------------------
# Helper for debugging
# ------------------------------------------------------------
proc mock_dump_message {mh} {

    puts [string map {"\r" "\n"} [msgget $mh]]
}
