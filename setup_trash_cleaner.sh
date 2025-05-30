#!/bin/bash

SCRIPT_DIR="$HOME/scripts"
SCRIPT_PATH="$SCRIPT_DIR/empty_trash.sh"
WRAPPER_PATH="$SCRIPT_DIR/run_trash_via_terminal.sh"
PLIST="$HOME/Library/LaunchAgents/com.user.trashcleaner.plist"
LABEL="com.user.trashcleaner"

if [[ "$1" == "--uninstall" ]]; then
    echo "🧹 Uninstalling trash cleaner..."
    launchctl bootout gui/$(id -u) "$PLIST" 2>/dev/null
    rm -f "$PLIST" "$SCRIPT_PATH" "$WRAPPER_PATH"
    echo "✅ Trash cleaner removed."
    exit 0
fi

mkdir -p "$SCRIPT_DIR"

cat <<'EOF' > "$SCRIPT_PATH"
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
  echo "👉 Enable Full Disk Access for Terminal:"
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
EOF

chmod +x "$SCRIPT_PATH"

cat <<EOF > "$WRAPPER_PATH"
#!/bin/bash
open -a Terminal "$SCRIPT_PATH"
EOF

chmod +x "$WRAPPER_PATH"

cat <<EOF > "$PLIST"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
 "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>$LABEL</string>

    <key>ProgramArguments</key>
    <array>
        <string>$WRAPPER_PATH</string>
    </array>

    <key>StartInterval</key>
    <integer>60</integer>

    <key>RunAtLoad</key>
    <true/>

    <key>StandardOutPath</key>
    <string>/tmp/trashcleaner.out</string>
    <key>StandardErrorPath</key>
    <string>/tmp/trashcleaner.err</string>
</dict>
</plist>
EOF

launchctl bootout gui/$(id -u) "$PLIST" 2>/dev/null
launchctl bootstrap gui/$(id -u) "$PLIST"

echo "✅ Installed LaunchAgent to empty Trash every minute."
echo "🛡️  Make sure Terminal has Full Disk Access:"
echo "   System Settings → Privacy & Security → Full Disk Access → Add Terminal"
echo "🚀 Running first cleanup manually via Terminal..."
open -a Terminal "$SCRIPT_PATH"
