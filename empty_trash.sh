#!/bin/bash

USER_ID=$(id -u)
TRASH_PATHS=(
  "$HOME/.Trash"
  "/Volumes/*/.Trashes/$USER_ID"
)

HAS_ACCESS=true
for path in "${TRASH_PATHS[@]}"; do
  for resolved in $(eval echo $path); do
    if [ -d "$resolved" ] && [ ! -w "$resolved" ]; then
      HAS_ACCESS=false
    fi
  done
done

if [ "$HAS_ACCESS" = false ]; then
  echo "⚠️  No access to Trash directories."
  echo "👉 Please enable Full Disk Access for Terminal:"
  echo "   System Settings > Privacy & Security > Full Disk Access"
  exit 1
fi

DELETED=false
for path in "${TRASH_PATHS[@]}"; do
  for resolved in $(eval echo $path); do
    if [ -d "$resolved" ]; then
      FILECOUNT=$(find "$resolved" -mindepth 1 | wc -l)
      if [ "$FILECOUNT" -gt 0 ]; then
        echo "🗑️  Found files in: $resolved"
        find "$resolved" -mindepth 1 -exec rm -rf {} + 2>/dev/null
        DELETED=true
      fi
    fi
  done
done

if [ "$DELETED" = true ]; then
  echo "✅ Trash emptied at $(date)"
else
  echo "ℹ️  Nothing to delete or no access."
fi
