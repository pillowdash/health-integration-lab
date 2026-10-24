#!/usr/bin/env bash
# scrub.sh — remove all traces of JBH/jbh/SJHH from tcl/ and prep for publish
set -euo pipefail
cd "$(dirname "$0")"

echo "=== 0. Check archives for embedded jbh/sjhh ==="
for z in $(find . -name '*.zip' 2>/dev/null | grep -v 'tcl.damaged' || true); do
  echo "--- $z"
  unzip -l "$z" 2>/dev/null | grep -iE 'jbh|sjhh' || echo "  ✓ filenames clean"
  # extract-in-memory scan for content (slow but thorough)
  tmp=$(mktemp -d)
  unzip -qq "$z" -d "$tmp" 2>/dev/null || true
  if grep -rqi "jbh\|sjhh" "$tmp" 2>/dev/null; then
    echo "  ⚠ CONTENT contains jbh/sjhh — exclude or rebuild this archive"
  else
    echo "  ✓ content clean"
  fi
  rm -rf "$tmp"
done

for z in $(find . -name '*.tar.gz' 2>/dev/null | grep -v 'tcl.damaged' || true); do
  echo "--- $z"
  tar -tzf "$z" 2>/dev/null | grep -iE 'jbh|sjhh' || echo "  ✓ filenames clean"
  tmp=$(mktemp -d)
  tar -xzf "$z" -C "$tmp" 2>/dev/null || true
  if grep -rqi "jbh\|sjhh" "$tmp" 2>/dev/null; then
    echo "  ⚠ CONTENT contains jbh/sjhh — exclude or rebuild"
  else
    echo "  ✓ content clean"
  fi
  rm -rf "$tmp"
done

echo ""
echo "=== 1. Delete .bak leftovers ==="
find tcl -name '*.bak' -type f -print -delete | wc -l
echo "   .bak files deleted"

echo ""
echo "=== 2. Delete the buggy one-off scripts ==="
rm -f tcl/basics/replace_str_in_files.tcl
rm -f repair.sh repair2.sh repair3.sh repair_tsh.sh
echo "   done"

echo ""
echo "=== 3. Rename OLIS files (path-level leak) ==="
cd tcl/olis_Tcl
[ -f olis_jbh_transform.tcl ]      && mv olis_jbh_transform.tcl      olis_tsh_transform.tcl      && echo "   olis_jbh_transform.tcl      → olis_tsh_transform.tcl"
[ -f tps_olis_jbh_out.tcl ]        && mv tps_olis_jbh_out.tcl        tps_olis_tsh_out.tcl        && echo "   tps_olis_jbh_out.tcl        → tps_olis_tsh_out.tcl"
[ -f test_olis_jbh_transform.tcl ] && mv test_olis_jbh_transform.tcl test_olis_tsh_transform.tcl && echo "   test_olis_jbh_transform.tcl → test_olis_tsh_transform.tcl"
cd ../..

echo ""
echo "=== 4. Replace UPPERCASE JBH → TSH in live files ==="
for f in $(grep -rlI "JBH" tcl/ 2>/dev/null || true); do
  perl -pi -e 's/\QJBH\E/TSH/g' -- "$f"
  echo "   $f"
done

echo ""
echo "=== 5. Replace lowercase jbh → tsh in live files ==="
for f in $(grep -rlI "jbh" tcl/ 2>/dev/null || true); do
  perl -pi -e 's/\Qjbh\E/tsh/g' -- "$f"
  echo "   $f"
done

echo ""
echo "=== 6. Fix identifier names that came out of step 4/5 ==="
# After step 4, olis_jbh_transform.tcl contains "package provide olis_tsh_transform 1.0"
# but tps_tsh_out.tcl and README already reference the new name from step 5.
# No extra work needed — step 5 caught everything.

echo ""
echo "=== 7. Verify: no jbh/sjhh anywhere in tcl/ (case-insensitive) ==="
if grep -rniI "jbh\|sjhh\|sjbh" tcl/ 2>/dev/null; then
  echo ""
  echo "⚠ Remaining hits above — fix by hand or re-run"
else
  echo "  ✓ ALL CLEAN"
fi
