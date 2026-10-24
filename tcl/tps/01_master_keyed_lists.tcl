# Start tclsh and type:
package require Tclx

# This is how Cloverleaf passes arguments in the background
set args "{MODE run} {MSGID mh_12345} {CONTEXT sms_ib_data}"

# Extracting the MODE
keylget args MODE mode
puts "The engine is currently in mode: $mode"

set user_args {{USER_ARGS { {TARGET_SYSTEM "OpenMRS"} {FILTER_CODES "A04,A31"} }}}
keylget user_args USER_ARGS.FILTER_CODES filter_codes
puts $filter_codes
