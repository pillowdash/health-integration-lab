# ============================================================
# string trim demo with HL7-style values
# ============================================================

puts "=== 1. Default whitespace trimming ==="

set facility "   TSH   "

puts "Before: <$facility>"
puts "After : <[string trim $facility]>"


puts ""
puts "=== 2. Trim selected characters ==="

set externalCode "###LAB123###"

puts "Before: <$externalCode>"
puts "After : <[string trim $externalCode "#"]>"


puts ""
puts "=== 3. Character set, NOT substring ==="

set value "xyxyORUyxy"

puts "Before: <$value>"
puts "After : <[string trim $value "xy"]>"

# Removes x OR y from the edges.


puts ""
puts "=== 4. CR/LF/space cleanup ==="

set dirtyCode "\r\n   OLIS   \r\n"

set trimChars " \t\r\n"

set cleanCode [string trim $dirtyCode $trimChars]

puts "Clean code: <$cleanCode>"


puts ""
puts "=== 5. HL7 OBX-5 cleanup ==="

set obx "OBX|1|ST|RESULT^Result||   POSITIVE   ||||F"

set fields [split $obx "|"]

set obx5 [lindex $fields 5]

puts "Raw OBX-5     = <$obx5>"

set obx5 [string trim $obx5]

puts "Clean OBX-5   = <$obx5>"

if {$obx5 eq "POSITIVE"} {
    puts "Result matched POSITIVE"
}


puts ""
puts "=== 6. Normalize facility before routing ==="

set msh4 "  tsh  "

set msh4 [string toupper [string trim $msh4]]

puts "Normalized MSH-4 = <$msh4>"

switch -exact -- $msh4 {

    TSH {
        puts "Route to TSH workflow"
    }

    STSH {
        puts "Route to STSH workflow"
    }

    default {
        puts "Unknown facility"
    }
}


puts ""
puts "=== 7. trim versus string map for phone ==="

set phone "  (905) 555-1234  "

# trim only removes leading/trailing spaces
set phone [string trim $phone]

puts "After trim      = <$phone>"

# map removes formatting anywhere
set phone [string map {
    "(" ""
    ")" ""
    "-" ""
    " " ""
} $phone]

puts "After string map = <$phone>"
