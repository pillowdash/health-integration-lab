source [file join [file dirname [info script]] olis_tsh_transform.tcl]

# Mock DB adapter ONLY for local testing.
proc olis_db_lookup {field incomingValue} {
    switch -exact -- $field {
        "OBR-15" { return [list "BLD" "Whole Blood"] }
        "OBR-4"  { return [list "TR10149-3" "CREATININE"] }
        "OBX-3"  { return [list "14683-7" "CREATININE:SCNC:PT:URINE:QN"] }
        default   { error "No mock mapping for $field <$incomingValue>" }
    }
}

set msg "MSH|^~\\&|EPIC|37|OLIS|OLIS|202610061200||ORU^R01|MSG1001|P|2.5\rPID|1||2000043386^^^ON^JHN~J0002107157^^^EPI^MR||SMITH^JOHN|||||123 Main^^Markham^ON^L3R1A1^CAN~1 Road^^Beijing^^100000^CHN||^PRN^PH^^52^^5512345678^^^^^^^^^^^1~^NET^Internet^a@b.ca|^PRN^PH^^^416^5551234^^^^^^^^^^^2\rPV1|1|O|||||1234^JONES^SARAH^^^^^^OLD|||||CPSO\rORC|RE|P1|F1|GROUP||||||||1234^JONES^SARAH||||||||||||123 St^^^^^^C\rOBR|1|ORD1001|LAB1001|TR10149-3^CREATININE^^CREATININE|||||||||||BLO^Blood^^A&Blood, Venous|1234^JONES^SARAH|555^PRN^PH|||||||POCT|F|||1234^COPY^DOC|||||||||||||||||2038134^2038134&Beaker\rSPM|1|||BLO^Blood\rOBX|1|CWE|14683-7^OLD^^CREATININE:SCNC:PT:URINE:QN||OLD^Old^SYS^ACIN^Acinetobacter||||||F\rNTE|1||First note\rNTE|2||Second note"

puts "=== INPUT ==="
puts [string map [list "\r" "\n"] $msg]
puts "\n=== OUTPUT ==="
set out [olis::transform_message $msg]
puts [string map [list "\r" "\n"] $out]
