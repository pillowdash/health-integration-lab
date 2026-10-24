# ============================================================================
# tps_olis_tsh_out.tcl
# Cloverleaf TPS wrapper for olis_tsh_transform.tcl
#
# Place both files where Cloverleaf Tcl can source them, then source the core
# library before this proc (or edit CORE_FILE below to the installed location).
#
# Standard Cloverleaf TPS contract used here:
#   keylget args MODE mode
#   keylget args MSGID mh
#   msgget / msgset
#   return disposition list: CONTINUE or KILL
# ============================================================================

# EDIT THIS PATH for the Cloverleaf site if the core library is not already sourced.
set ::OLIS_CORE_FILE "olis_tsh_transform.tcl"

if {[llength [info commands olis::transform_message]] == 0} {
    if {[file exists $::OLIS_CORE_FILE]} {
        source $::OLIS_CORE_FILE
    } else {
        error "OLIS core library not loaded and not found at $::OLIS_CORE_FILE"
    }
}

proc tps_olis_tsh_out {args} {
    keylget args MODE mode
    set dispList {}

    switch -exact -- $mode {
        start {
            # Optional initialization belongs here.
            # If using a persistent DB connection for olis_db_lookup, open it here.
            return $dispList
        }

        run {
            keylget args MSGID mh
            set msg [msgget $mh]

            if {[catch {
                set newMsg [olis::transform_message $msg]
            } err options]} {
                set controlId "UNKNOWN"
                catch {
                    set fs [string index $msg 3]
                    set msh [lindex [split $msg "\r"] 0]
                    set controlId [olis::get_field $msh 10 $fs]
                }

                olis::log ERROR "MSH-10=$controlId transformation failed: $err"

                # Safer default: do not send an incompletely transformed OLIS message.
                lappend dispList "KILL $mh"
                return $dispList
            }

            msgset $mh $newMsg
            lappend dispList "CONTINUE $mh"
            return $dispList
        }

        time {
            return $dispList
        }

        shutdown {
            # Close persistent DB resources here if your adapter uses them.
            return $dispList
        }

        default {
            error "Unknown MODE <$mode> in tps_olis_tsh_out"
        }
    }
}
