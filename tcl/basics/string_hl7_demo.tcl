# ============================================================
# TCL STRING COMMAND DEMO USING HL7 DATA
#
# Main commands covered:
#
#   string length
#   string compare
#   string equal
#   string match
#   string first
#   string last
#   string index
#   string range
#   string trim
#   string trimleft
#   string trimright
#   string toupper
#   string tolower
#   string map
#   string replace
#   string is
#
# Plus:
#
#   format
#
# NOTE:
# "format" is a separate Tcl command.
# It is NOT "string format".
# ============================================================


set msh "MSH|^~\\&|EPIC|TSH|OLIS|OLIS|202610060900||ORU^R01|MSG1001|P|2.5"
set pid "PID|1||123456^^^TSH^MR||Smith^John||19800101|M"
set obx "OBX|1|NM|K^Potassium||5.8|mmol/L|3.5-5.1|H|||F"

puts "=== ORIGINAL HL7 ==="
puts $msh
puts $pid
puts $obx


# ============================================================
# 1. string length
#
# Returns the number of characters in a string.
# ============================================================

puts ""
puts "=== string length ==="

puts "PID length = [string length $pid]"
puts "OBX length = [string length $obx]"


# ============================================================
# 2. string compare
#
# Lexicographically compares two strings.
#
# Returns:
#
#   -1   first string comes before second
#    0   strings are equal
#    1   first string comes after second
#
# For simple equality testing, "string equal" or "eq"
# is usually clearer.
# ============================================================

puts ""
puts "=== string compare ==="

set msgType1 "ORU"
set msgType2 "ORU"
set msgType3 "SIU"

puts "ORU vs ORU = [string compare $msgType1 $msgType2]"
puts "ORU vs SIU = [string compare $msgType1 $msgType3]"


# Case-insensitive comparison
puts "oru vs ORU nocase = [string compare -nocase "oru" "ORU"]"


# ============================================================
# 3. string equal
#
# Usually clearer than string compare when we only care
# whether two strings are the same.
# ============================================================

puts ""
puts "=== string equal ==="

set trigger "R01"

if {[string equal $trigger "R01"]} {
    puts "This is an R01 trigger"
}

if {[string equal -nocase "tsh" "TSH"]} {
    puts "tsh and TSH are equal when using -nocase"
}


# In ordinary Tcl conditions, this is even more common:
#
#     if {$trigger eq "R01"} ...
#
if {$trigger eq "R01"} {
    puts "eq operator also says trigger is R01"
}


# ============================================================
# 4. string match
#
# Uses glob-style matching:
#
#   *   any characters
#   ?   exactly one character
#
# Very useful for patterns.
# ============================================================

puts ""
puts "=== string match ==="

set messageType "ORU^R01"

if {[string match "ORU*" $messageType]} {
    puts "$messageType is an ORU message"
}

set facility "TSH20001"

if {[string match "TSH*" $facility]} {
    puts "$facility starts with TSH"
}


# ============================================================
# 5. string first
#
# Finds the first occurrence of a substring.
#
# Returns index, or -1 if not found.
# ============================================================

puts ""
puts "=== string first ==="

set position [string first "Potassium" $obx]

puts "Potassium begins at character index $position"

if {[string first "Potassium" $obx] >= 0} {
    puts "OBX contains Potassium"
}


# ============================================================
# 6. string last
#
# Finds the last occurrence of a substring.
# ============================================================

puts ""
puts "=== string last ==="

set sample "TSH-EPIC-TSH-OLIS"

puts "First TSH = [string first "TSH" $sample]"
puts "Last TSH  = [string last "TSH" $sample]"


# ============================================================
# 7. string index
#
# Gets ONE character by position.
#
# Tcl indexes start at 0.
# ============================================================

puts ""
puts "=== string index ==="

set sex "M"

puts "First character = [string index $sex 0]"

set mrn "123456"

puts "First MRN digit = [string index $mrn 0]"
puts "Last MRN digit  = [string index $mrn end]"


# ============================================================
# 8. string range
#
# Extracts part of a string.
#
# Both indexes are inclusive.
# ============================================================

puts ""
puts "=== string range ==="

set date "20261006"

puts "Year  = [string range $date 0 3]"
puts "Month = [string range $date 4 5]"
puts "Day   = [string range $date 6 7]"


# "end" means last character.
puts "Last 4 characters of MRN = [string range $mrn end-3 end]"


# ============================================================
# 9. string trim
#
# Removes whitespace from BOTH ends.
#
# Extremely useful with messy incoming interface values.
# ============================================================

puts ""
puts "=== string trim ==="

set rawFacility "   TSH   "

puts "Before = <$rawFacility>"

set cleanedFacility [string trim $rawFacility]

puts "After  = <$cleanedFacility>"


# ============================================================
# 10. string trimleft / trimright
# ============================================================

puts ""
puts "=== trimleft / trimright ==="

set rawValue "   123456   "

puts "trimleft  = <[string trimleft $rawValue]>"
puts "trimright = <[string trimright $rawValue]>"


# trim can also remove specific characters.
set phone "###9055551234###"

puts "Trim # characters = [string trim $phone "#"]"


# ============================================================
# 11. string toupper / tolower
#
# Useful for normalization before comparison.
# ============================================================

puts ""
puts "=== toupper / tolower ==="

set patientLastName "Smith"
set facilityCode "tsh"

puts "Upper last name = [string toupper $patientLastName]"
puts "Upper facility  = [string toupper $facilityCode]"
puts "Lower facility  = [string tolower "TSH"]"


# Common normalization pattern:
set normalizedFacility [string toupper [string trim $rawFacility]]

puts "Normalized facility = $normalizedFacility"


# ============================================================
# 12. string map
#
# Performs multiple substitutions.
#
# Very useful for phone normalization and HL7 cleanup.
# ============================================================

puts ""
puts "=== string map ==="

set phone "(905) 555-1234"

set normalizedPhone [string map {
    "(" ""
    ")" ""
    "-" ""
    " " ""
} $phone]

puts "Original phone   = $phone"
puts "Normalized phone = $normalizedPhone"


# Another example: human-readable HL7.
set msg "$msh\r$pid\r$obx"

puts ""
puts "HL7 for display:"
puts [string map {"\r" "\n"} $msg]


# ============================================================
# 13. string replace
#
# Replaces characters by CHARACTER INDEX.
#
# Important:
# This operates on character positions,
# NOT HL7 field positions.
# ============================================================

puts ""
puts "=== string replace ==="

set code "ABC123"

set changed [string replace $code 0 2 "XYZ"]

puts "Original = $code"
puts "Changed  = $changed"


# ============================================================
# 14. string is
#
# Validates what kind of value a string represents.
#
# Very useful before numeric processing.
# ============================================================

puts ""
puts "=== string is ==="

set obxValue1 "5.8"
set obxValue2 "POSITIVE"
set patientAge "45"

puts "5.8 double?     [string is double -strict $obxValue1]"
puts "POSITIVE double? [string is double -strict $obxValue2]"
puts "45 integer?     [string is integer -strict $patientAge]"


if {[string is double -strict $obxValue1]} {
    puts "OBX-5 '$obxValue1' can safely be treated as numeric"
}


# ============================================================
# 15. format
#
# IMPORTANT:
# "format" is its own Tcl command.
#
# Similar idea to printf formatting.
# ============================================================

puts ""
puts "=== format ==="

set testName "Potassium"
set result 5.8
set units "mmol/L"

set output [format "Test: %-12s Result: %6.2f %s" \
    $testName $result $units]

puts $output


# %s = string
# %d = integer
# %f = floating point
# %.2f = floating point with 2 decimal places

set msgNumber 123

puts [format "Message number: %06d" $msgNumber]


# ============================================================
# 16. Combine several string operations
#
# This is closer to real interface work.
# ============================================================

puts ""
puts "=== REALISTIC NORMALIZATION ==="

set incomingFacility "   tsh   "

set normalizedFacility \
    [string toupper [string trim $incomingFacility]]

puts "Incoming facility   = <$incomingFacility>"
puts "Normalized facility = <$normalizedFacility>"

if {$normalizedFacility eq "TSH"} {
    puts "Facility accepted"
}


# ============================================================
# 17. Extract MSH-9 and inspect it
#
# Here we combine string operations with the HL7 split
# operations we already know.
# ============================================================

puts ""
puts "=== MSH-9 EXAMPLE ==="

set mshFields [split $msh "|"]

# MSH-9 is Tcl index 8 because MSH-1 is the "|" itself.
set msh9 [lindex $mshFields 8]

puts "MSH-9 = $msh9"

if {[string match "ORU^*" $msh9]} {
    puts "This belongs to the ORU message family"
}

puts "Uppercase MSH-9 = [string toupper $msh9]"


puts ""
puts "=== END ==="
