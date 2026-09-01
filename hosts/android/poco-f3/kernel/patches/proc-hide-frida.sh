#!/usr/bin/env bash
# Patch fs/proc/task_mmu.c to filter Frida-related entries from
# /proc/PID/maps and /proc/PID/smaps. VMAs whose backing file dentry
# name contains "frida" or "linjector" are silently omitted.
#
# Uses dentry->d_name.name (lockless, no allocation) instead of d_path()
# which is unsafe under mmap_sem and caused a bootloop.
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
/^static int show_map\(struct seq_file \*m, void \*v\)/ && !inserted {
    print "static bool should_hide_vma(struct vm_area_struct *vma)"
    print "{"
    print "\tstruct file *file = vma->vm_file;"
    print "\tconst char *name;"
    print ""
    print "\tif (!file || !file->f_path.dentry)"
    print "\t\treturn false;"
    print ""
    print "\tname = file->f_path.dentry->d_name.name;"
    print "\tif (!name)"
    print "\t\treturn false;"
    print ""
    print "\tif (strstr(name, \"frida\") || strstr(name, \"linjector\"))"
    print "\t\treturn true;"
    print "\treturn false;"
    print "}"
    print ""
    inserted = 1
}
{ print }
' "$FILE" > "$FILE.tmp" && mv "$FILE.tmp" "$FILE"

awk '
/^static int show_map\(struct seq_file \*m, void \*v\)/ { in_fn=1 }
in_fn && /^\{[[:space:]]*$/ {
    print $0
    print "\tif (should_hide_vma((struct vm_area_struct *)v)) return 0;"
    in_fn=0
    next
}
{ print }
' "$FILE" > "$FILE.tmp" && mv "$FILE.tmp" "$FILE"

awk '
/^static int show_smap\(struct seq_file \*m, void \*v\)/ { in_fn=1 }
in_fn && /^\{[[:space:]]*$/ {
    print $0
    print "\tif (should_hide_vma((struct vm_area_struct *)v)) return 0;"
    in_fn=0
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
