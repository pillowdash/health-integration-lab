# ============================================================
# LOCAL TEST OF CLOVERLEAF OLIS TPS
# ============================================================

set scriptDir [file dirname [file normalize [info script]]]

# Load our simulated Cloverleaf commands.
source [file join $scriptDir cloverleaf_mock.tcl]

# Load OLIS transformation core.
source [file join $scriptDir ../olis_Tcl/olis_tsh_transform.tcl]

# Load Cloverleaf TPS wrapper.
source [file join $scriptDir ../olis_Tcl/tps_olis_tsh_out.tcl]


# ------------------------------------------------------------
# If the OLIS transformation reaches rules that require a DB
# lookup, provide a mock DB adapter for local testing.
# ------------------------------------------------------------
proc olis_db_lookup {field incomingValue} {

    switch -exact -- $field {

        "OBR-15" {
            return [list "BLD" "Whole Blood"]
        }

        "OBR-4" {
            return [list "TR10149-3" "CREATININE"]
        }

        "OBX-3" {
            return [list \
                "14683-7" \
                "CREATININE:SCNC:PT:URINE:QN"]
        }

        default {
            error "No mock DB mapping for $field <$incomingValue>"
        }
    }
}


# ------------------------------------------------------------
# Sample ORU message
# ------------------------------------------------------------
set hl7msg \
"MSH|^~\\&|EPIC|37|OLIS|OLIS|202610061200||ORU^R01|MSG1001|P|2.5\rPID|1||2000043386^^^ON^JHN~J0002107157^^^EPI^MR||SMITH^JOHN\rOBR|1|ORD1001|LAB1001|TR10149-3^CREATININE\rOBX|1|NM|14683-7^CREATININE||5.8|mmol/L|||||F"


# Create fake Cloverleaf message handle.
set mh "mh_1001"

mock_create_message $mh $hl7msg


puts "=== BEFORE TPS ==="
mock_dump_message $mh


# ------------------------------------------------------------
# Build the same style of keyed-list arguments Cloverleaf
# supplies to a TPS procedure.
# ------------------------------------------------------------
set tpsArgs ""

keylset tpsArgs MODE run
keylset tpsArgs MSGID $mh


puts ""
puts "TPS arguments:"
puts $tpsArgs


# ------------------------------------------------------------
# Important:
#
# tps_olis_tsh_out was declared:
#
#     proc tps_olis_tsh_out {args}
#
# {*} expands the keyed-list entries so that the proc's
# special "args" variable receives a valid keyed list.
# ------------------------------------------------------------
set disposition [tps_olis_tsh_out {*}$tpsArgs]


puts ""
puts "TPS disposition:"
puts $disposition


puts ""
puts "=== AFTER TPS ==="
mock_dump_message $mh
