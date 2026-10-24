# ============================================================
# TCL LIST COMMANDS WITH HL7 DATA
# ============================================================


# ------------------------------------------------------------
# An ORU^R01 message
#
# Actual HL7 uses \r between segments.
# ------------------------------------------------------------

set msg "MSH|^~\\&|LAB|TSH|EPIC|TSH|202610050800||ORU^R01|MSG1001|P|2.5\rPID|1||123456^^^TSH^MR||SMITH^JOHN\rOBR|1|||BMP^Basic Metabolic Panel\rOBX|1|NM|K^Potassium||5.8|mmol/L|3.5-5.1|H|||F"


puts "=== ORIGINAL MESSAGE ==="

puts [string map {"\r" "\n"} $msg]


# ============================================================
# 1. SPLIT
#
# Convert the HL7 message STRING into a Tcl LIST of segments.
# ============================================================

set segments [split $msg "\r"]

puts ""
puts "=== SPLIT MESSAGE INTO SEGMENTS ==="

puts "Number of segments = [llength $segments]"


# ============================================================
# 2. LLENGTH
#
# Our list currently contains:
#
#   index 0 = MSH
#   index 1 = PID
#   index 2 = OBR
#   index 3 = OBX
# ============================================================

puts "Segment count = [llength $segments]"


# ============================================================
# 3. LINDEX
#
# Retrieve a specific segment.
# ============================================================

set obr [lindex $segments 2]
set obx [lindex $segments 3]

puts ""
puts "OBR segment:"
puts $obr

puts ""
puts "OBX segment:"
puts $obx


# ------------------------------------------------------------
# We can split the OBX itself into another list.
# ------------------------------------------------------------

set obxFields [split $obx "|"]

puts ""
puts "OBX-3 = [lindex $obxFields 3]"
puts "OBX-5 = [lindex $obxFields 5]"
puts "OBX-8 = [lindex $obxFields 8]"


# ============================================================
# 4. LAPPEND
#
# Append a new segment to the existing segment list.
#
# lappend modifies the variable directly.
# ============================================================

lappend segments "NTE|1||Potassium result reviewed"

puts ""
puts "=== AFTER LAPPEND ==="

foreach segment $segments {
    puts $segment
}


# ============================================================
# 5. LINSERT
#
# Insert an NTE segment BEFORE the existing OBX.
#
# Current indexes:
#
#   0 MSH
#   1 PID
#   2 OBR
#   3 OBX
#   4 NTE   <-- from the lappend above
#
# linsert RETURNS a new list.
# ============================================================

set segments2 \
    [linsert $segments 3 \
        "NTE|1||Inserted before OBX"]

puts ""
puts "=== AFTER LINSERT AT INDEX 3 ==="

foreach segment $segments2 {
    puts $segment
}


# ============================================================
# 6. LSET
#
# Modify one existing element IN PLACE.
#
# Let's replace the PID segment.
# ============================================================

set newPid \
    "PID|1||999999^^^TSH^MR||DOE^JANE"

lset segments2 1 $newPid

puts ""
puts "=== AFTER LSET PID ==="

foreach segment $segments2 {
    puts $segment
}


# ============================================================
# 7. LREPLACE
#
# Replace one or more elements.
#
# Replace segment at index 3 with a different NTE.
#
# Since first index == last index, only ONE element is removed.
# ============================================================

set segments3 \
    [lreplace $segments2 3 3 \
        "NTE|1||Replacement note"]

puts ""
puts "=== AFTER LREPLACE ==="

foreach segment $segments3 {
    puts $segment
}


# ============================================================
# 8. JOIN
#
# Convert the segment LIST back into one HL7 STRING.
# ============================================================

set newMsg [join $segments3 "\r"]

puts ""
puts "=== REBUILT HL7 MESSAGE ==="

puts [string map {"\r" "\n"} $newMsg]
