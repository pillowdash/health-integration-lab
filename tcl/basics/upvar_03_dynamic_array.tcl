# ------------------------------------------------------------
# CASE 3
#
# We have three Tcl associative arrays:
#
#     patientData
#     resultData
#     orderData
#
# Depending on the HL7 message type, we dynamically choose
# WHICH ARRAY should be modified.
# ------------------------------------------------------------

# scenario - Runtime business logic chooses the variable

# ------------------------------------------------------------
# Patient information - imagine this came from an ADT message
# ------------------------------------------------------------

array set patientData {
    MRN       123456
    LASTNAME  SMITH
    FIRSTNAME JOHN
    FACILITY  TSH
}


# ------------------------------------------------------------
# Result information - imagine this came from an ORU message
# ------------------------------------------------------------

array set resultData {
    TEST       POTASSIUM
    VALUE      5.8
    UNITS      mmol/L
    FLAG       H
}


# ------------------------------------------------------------
# Order information - imagine this came from an ORM message
# ------------------------------------------------------------

array set orderData {
    ORDER_ID   ORD1001
    PROCEDURE  CBC
    STATUS     NEW
}


# ------------------------------------------------------------
# Generic procedure.
#
# It does NOT care whether it receives patientData,
# resultData, or orderData.
#
# It receives an ARRAY NAME and aliases it locally as "record".
# ------------------------------------------------------------

proc update_record {arrayName key value} {

    upvar 1 $arrayName record

    puts "Updating array: $arrayName"

    # Because "record" is an alias,
    # this modifies the caller's actual array.
    set record($key) $value
}


# ------------------------------------------------------------
# Choose an HL7 message type.
#
# Try changing this to:
#
#     ADT
#     ORU
#     ORM
# ------------------------------------------------------------

set messageType "ORU"


# ------------------------------------------------------------
# Dynamically decide which ARRAY NAME to use.
# ------------------------------------------------------------

switch -exact -- $messageType {

    ADT {
        set selectedRecord "patientData"
    }

    ORU {
        set selectedRecord "resultData"
    }

    ORM {
        set selectedRecord "orderData"
    }

    default {
        error "Unsupported HL7 message type: $messageType"
    }
}


puts "Message Type   = $messageType"
puts "selectedRecord = $selectedRecord"


# ------------------------------------------------------------
# selectedRecord contains the NAME of another variable.
#
# For ORU:
#
#     selectedRecord = resultData
#
# Therefore:
#
#     $selectedRecord
#
# evaluates to:
#
#     resultData
#
# And this call becomes:
#
#     update_record resultData SOURCE EPIC
# ------------------------------------------------------------

update_record $selectedRecord SOURCE EPIC


puts ""
puts "=== RESULTS ==="

puts ""
puts "patientData:"
foreach key [lsort [array names patientData]] {
    puts "  $key = $patientData($key)"
}

puts ""
puts "resultData:"
foreach key [lsort [array names resultData]] {
    puts "  $key = $resultData($key)"
}

puts ""
puts "orderData:"
foreach key [lsort [array names orderData]] {
    puts "  $key = $orderData($key)"
}
