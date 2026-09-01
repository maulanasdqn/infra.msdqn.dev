#!/usr/bin/env bash
# Patch fs/proc/task_mmu.c to filter Frida-related entries from
# /proc/PID/maps and /proc/PID/smaps. VMAs whose backing file path
# contains "frida" or "linjector" are silently omitted from the output,
# so apps reading their own /proc/self/maps cannot detect Frida's
# injected agent libraries.
#
# Idempotent: re-running on an already-patched tree is a no-op.
# Applied by build.sh when STEALTH=1.
set -euo pipefail

KDIR="${1:?usage: $0 <kernel-source-dir>}"
FILE="$KDIR/fs/proc/task_mmu.c"

[ -f "$FILE" ] || { echo "ERROR: $FILE not found"; exit 1; }

if grep -q 'should_hide_vma' "$FILE"; then
  echo "proc maps filter: already applied"
  exit 0
fi

cp "$FILE" "$FILE.orig"

awk '
/^static void show_map_vma\(struct seq_file/ {
    print "static bool should_hide_vma(struct vm_area_struct *vma)"
    print "{"
    print "\tstruct file *file = vma->vm_file;"
    print "\tchar buf[256];"
    print "\tchar *p;"
    print ""
    print "\tif (!file)"
    print "\t\treturn false;"
    print "\tp = d_path(&file->f_path, buf, sizeof(buf));"
    print "\tif (IS_ERR(p))"
    print "\t\treturn false;"
    print "\tif (strstr(p, \"frida\") || strstr(p, \"linjector\"))"
    print "\t\treturn true;"
    print "\treturn false;"
    print "}"
    print ""
}
{ print }
' "$FILE" > "$FILE.tmp" && mv "$FILE.tmp" "$FILE"

awk '
/^static int show_map\(struct seq_file \*m, void \*v\)/ { in_show_map=1 }
in_show_map && /^\{[[:space:]]*$/ {
    print $0
    print "\tif (should_hide_vma((struct vm_area_struct *)v)) return 0;"
    in_show_map=0
    next
}
{ print }
' "$FILE" > "$FILE.tmp" && mv "$FILE.tmp" "$FILE"

awk '
/^static int show_smap\(struct seq_file \*m, void \*v\)/ { in_show_smap=1 }
in_show_smap && /^\{[[:space:]]*$/ {
    print $0
    print "\tif (should_hide_vma((struct vm_area_struct *)v)) return 0;"
    in_show_smap=0
    next
}
{ print }
' "$FILE" > "$FILE.tmp" && mv "$FILE.tmp" "$FILE"

if grep -q 'should_hide_vma' "$FILE"; then
  echo "proc maps filter: applied to $FILE"
else
  echo "ERROR: patch did not apply — restoring original"
  mv "$FILE.orig" "$FILE"
  exit 1
fi
rm -f "$FILE.orig"
