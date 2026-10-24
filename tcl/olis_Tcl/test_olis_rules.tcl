source [file join [file dirname [info script]] olis_tsh_transform.tcl]

proc assert_equal {label actual expected} {
    if {$actual ne $expected} {
        puts stderr "FAIL $label\n  actual:   <$actual>\n  expected: <$expected>"
        exit 1
    }
    puts "PASS $label"
}

# PID-11: keep CAN/USA/blank, remove CHN.
set pid11 {123 Main^^Markham^ON^L3R1A1^CAN~1 Road^^Beijing^^100000^CHN~No Country^^^^^}
set got [olis::transform_pid11 $pid11]
set exp {123 Main^^Markham^ON^L3R1A1^CAN~No Country^^^^^}
assert_equal "PID-11 country suppression" $got $exp

# PID-13 10 digit local number -> area/local split, trailing serial removed.
set got [olis::transform_xtn_field {^PRN^PH^^52^^5512345678^^^^^^^^^^^1} 13]
assert_equal "PID-13 XTN normalization" $got {^PRN^PH^^52^551^2345678}

# PID-14 phone use code -> WPN and trailing serial removed.
set got [olis::transform_xtn_field {^PRN^PH^^^416^5551234^^^^^^^^^^^2} 14]
assert_equal "PID-14 WPN normalization" $got {^WPN^PH^^^416^5551234}

# PID-3 ON JHN wins.
lassign [olis::transform_pid3 {2000043386^^^ON^JHN~J0002107157^^^EPI^MR}] got hasJhn
assert_equal "PID-3 ON JHN selection" $got {2000043386^^^^JHN^^^^ON&Ontario&HL70347}
assert_equal "PID-3 has JHN" $hasJhn 1

# PID-3 latest change: if JHN exists but not ON, use MR.
lassign [olis::transform_pid3 {9090909090^^^BC^JHN~J0002107157^^^EPI^MR}] got hasJhn
assert_equal "PID-3 non-ON JHN falls back to MR" $got {J0002107157^^^&2.16.840.1.113883.3.59.1:4014&ISO^MR}

# XCN mapping.
set xcn {1234^JONES^SARAH^^^^^^OLD^^^^CPSO}
set got [olis::normalize_xcn $xcn]
assert_equal "XCN CPSO->MDL" [olis::get_component $got 13] MDL
assert_equal "XCN component 9 nulled" [olis::get_component $got 9] ""
assert_equal "XCN component 22 authority" [olis::get_component $got 22] {ON&Ontario&HL70347}

# OBX empty + OBR-25=C.
set obx {OBX|1|NM|K^Potassium||||||||F}
set got [olis::transform_obx_segment $obx | C]
assert_equal "OBX empty corrected type" [olis::get_field $got 2 |] ST
assert_equal "OBX empty corrected value" [olis::get_field $got 5 |] {-}
assert_equal "OBX empty corrected status" [olis::get_field $got 11 |] W

# NTE merge.
set got [olis::merge_nte_segments [list {NTE|1||One} {NTE|2||Two}] |]
assert_equal "NTE merge" [olis::get_field $got 3 |] {One\.br\Two}

puts "ALL TESTS PASSED"
