# ============================================================
# TCL regexp / regsub DEMO WITH HL7 DATA
# ============================================================

set msh "MSH|^~\\&|LAB|TSH|EPIC|TSH|202610061000||ORU^R01|MSG1001|P|2.5"

set pid "PID|1||123456^^^TSH^MR||SMITH^JOHN||19800101|M|||||+1 (905) 555-1234^PRN^PH"

set obr "OBR|1|ORD1001|LAB1001|BMP^Basic Metabolic Panel"

set obx "OBX|1|NM|K^Potassium||5.8|mmol/L|3.5-5.1|H|||F"

set nte {NTE|1||Result   reviewed by lab. Comment: "repeat repeat". A&B}

set msg "$msh\r$pid\r$obr\r$obx\r$nte"


puts "=== HL7 MESSAGE ==="

puts [string map {"\r" "\n"} $msg]


# ============================================================
# 1. REGEXP RETURN VALUE + CAPTURE GROUPS
# ============================================================

puts ""
puts "=== 1. MSH-9 validation ==="

set mshFields [split $msh "|"]

# MSH-9 = Tcl index 8
set msh9 [lindex $mshFields 8]

puts "MSH-9 = $msh9"


# Pattern:
#
# ^                 beginning
# ([A-Z]{3})        exactly 3 uppercase letters
# \^                literal HL7 component separator ^
# ([A-Z][0-9]{2})   R01 / A08 / S12 etc.
# $                 end
#
set result [regexp \
    {^([A-Z]{3})\^([A-Z][0-9]{2})$} \
    $msh9 \
    fullMatch \
    messageCode \
    triggerEvent]


puts "regexp result = $result"
puts "Full match    = $fullMatch"
puts "Message code  = $messageCode"
puts "Trigger event = $triggerEvent"


# ============================================================
# 2. CAPTURE HL7 COMPONENTS
# ============================================================

puts ""
puts "=== 2. OBX-3 components ==="

set obxFields [split $obx "|"]

set obx3 [lindex $obxFields 3]

puts "OBX-3 = $obx3"


# [^^]+ means:
#
# any characters except ^
#
if {[regexp {^([^^]+)\^(.+)$} \
        $obx3 \
        full \
        code \
        description]} {

    puts "Full          = $full"
    puts "OBX-3.1 code  = $code"
    puts "OBX-3.2 text  = $description"
}


# ============================================================
# 3. VALIDATE NUMERIC OBX-5
# ============================================================

puts ""
puts "=== 3. Numeric validation ==="

set obx5 [lindex $obxFields 5]

puts "OBX-5 = $obx5"


# Allows:
#
# 5
# 5.8
# -5
# -5.8
#
if {[regexp {^-?[0-9]+(?:\.[0-9]+)?$} $obx5]} {

    puts "OBX-5 is numeric"

} else {

    puts "OBX-5 is NOT numeric"
}


# ============================================================
# 4. REGEXP -ALL
# ============================================================

puts ""
puts "=== 4. Count words in NTE-3 ==="

set nteFields [split $nte "|"]

set noteText [lindex $nteFields 3]

puts "NTE-3 = $noteText"


# \y = word boundary
# \w = word character
#
set wordCount [regexp -all {\y\w+\y} $noteText]

puts "Word-like tokens = $wordCount"


# ============================================================
# 5. CAPTURE QUOTED TEXT
# ============================================================

puts ""
puts "=== 5. Quoted text ==="


# Group 1 captures either " or '
#
# \1 requires the same quote to close it.
#
if {[regexp {(["'])[^"']*\1} \
        $noteText \
        quotedText]} {

    puts "Quoted text = $quotedText"
}


# ============================================================
# 6. FIND A REPEATED WORD
# ============================================================

puts ""
puts "=== 6. Repeated word ==="

puts "noteText = $noteText"

# First capture a whole word.
# Later \1 requires the same word again.
#
# -nocase means Repeat == repeat.
#
if {[regexp -nocase \
        {(\y\w+\y).*\y\1\y} \
        $noteText \
        wholeMatch \
        repeatedWord]} {

    puts "Repeated word = $repeatedWord"
}

# regexp {(\y\w+\y).+\1} $string => word

# Here:
# \w  = word character
# \y  = word boundary
# (...) = capture a whole word
# \1  = find the same captured word again later

# And this:
# =>

# is not an operator. It is just a variable name chosen to hold the complete match.
# People often use -> or => as a disposable match variable because it visually says:
# “I don't really care about the full match.”

# So:
# regexp PATTERN $string -> word

# means:
# ->   = whole match
# word = first capture group


# ============================================================
# 7. REGSUB - PHONE NORMALIZATION
# ============================================================

puts ""
puts "=== 7. Phone normalization ==="

set pidFields [split $pid "|"]

set pid13 [lindex $pidFields 13]

set xtnComponents [split $pid13 "^"]

set phone [lindex $xtnComponents 0]

puts "Original phone = $phone"


# Anything that is NOT:
#
# 0-9
# or +
#
# gets removed.
#
regsub -all \
    {[^0-9+]} \
    $phone \
    {} \
    normalizedPhone


puts "Normalized phone = $normalizedPhone"


# ============================================================
# 8. REGSUB - NORMALIZE EXTRA WHITESPACE
# ============================================================

puts ""
puts "=== 8. Clean NTE whitespace ==="


# \s+ means one or more whitespace characters.
#
regsub -all \
    {\s+} \
    [string trim $noteText] \
    { } \
    cleanNote


puts "Original = <$noteText>"
puts "Clean    = <$cleanNote>"


# ============================================================
# 9. MATCH A LITERAL HL7 CARET
# ============================================================

puts ""
puts "=== 9. HL7 component separator ^ ==="

set sample "K^Potassium"


if {[regexp {\^} $sample caret]} {

    puts "Found literal caret: $caret"
}


regexp \
    {([A-Z])\^([A-Za-z]+)} \
    $sample \
    full \
    beforeCaret \
    afterCaret


puts "Before ^ = $beforeCaret"
puts "After  ^ = $afterCaret"


# ============================================================
# 10. REGSUB WITH CAPTURE GROUPS
# ============================================================

puts ""
puts "=== 10. Reorder components ==="

set codedValue "K^Potassium"


# Capture:
#
# \1 = K
# \2 = Potassium
#
# Replacement:
#
# \2 (code=\1)
#
regsub \
    {([^^]+)\^([^^]+)} \
    $codedValue \
    {\2 (code=\1)} \
    prettyValue


puts "$codedValue -> $prettyValue"


# ============================================================
# 11. HL7 ESCAPING EXAMPLE
#
# & is the HL7 subcomponent separator.
#
# If an interface specification requires an actual &
# inside data to be escaped, HL7's escape representation
# is typically:
#
#     \T\
#
# IMPORTANT:
# Do this only at the FIELD VALUE level and only if required
# by the interface specification.
# ============================================================

puts ""
puts "=== 11. Escape & in field content ==="

set freeText "A&B"


regsub -all \
    {&} \
    $freeText \
    {\\T\\} \
    escapedText


puts "Original = $freeText"
puts "Escaped  = $escapedText"
