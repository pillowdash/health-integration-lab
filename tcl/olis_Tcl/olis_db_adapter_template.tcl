# ============================================================================
# olis_db_adapter_template.tcl
# Adapter contract expected by olis_tsh_transform.tcl
#
# The spreadsheet specifies SQL Server OLIS_Mapping and dbo.RetrieveValue.
# Database connectivity differs by Cloverleaf version/site (ODBC package,
# database protocol, persistent connection wrapper, etc.), so the transformation
# library intentionally isolates DB access behind this one procedure.
#
# Implement this proc using your site's approved Cloverleaf DB method.
# It MUST return a two-element Tcl list:
#
#     {OutgoingCode OutgoingDescription}
#
# Inputs:
#     field          e.g. OBR-4, OBR-15, OBX-3
#     incomingValue  raw source value supplied by the transform
#
# The workbook DB sheet indicates parameters conceptually like:
#   @organization = 'TSH'
#   @field        = <field>
#   @incomingValue= <incomingValue>
#   @env          = 'T' or 'P'
#
# Do NOT use this template unchanged in production; wire it to the actual
# stored procedure and verify that @incomingValue is included in the WHERE
# logic of the deployed procedure.
# ============================================================================

proc olis_db_lookup {field incomingValue} {
    error "Configure olis_db_lookup for field=$field incomingValue=<$incomingValue>"
}
