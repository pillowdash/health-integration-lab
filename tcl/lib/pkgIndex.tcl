package ifneeded hl7utils 1.1 \
    [list source [file join $dir hl7_utils.tcl]]

package ifneeded logger 1.0 \
    [list source [file join $dir logging.tcl]]

package ifneeded xtn 1.0 \
    [list source [file join $dir xtn.tcl]]

package ifneeded orurules 1.0 \
    [list source [file join $dir oru_rules.tcl]]
