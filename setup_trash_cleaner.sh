#!/bin/bash

SCRIPT_DIR="$HOME/scripts"
SCRIPT_PATH="$SCRIPT_DIR/empty_trash.sh"
PLIST="$HOME/Library/LaunchAgents/com.user.trashcleaner.plist"
LABEL="com.user.trashcleaner"

if [[ "$1" == "--uninstall" ]]; then
    echo "🧹 Uninstalling trash cleaner..."
    launchctl bootout gui/$(id -u) "$PLIST" 2>/dev/null
    rm -f "$PLIST" "$SCRIPT_PATH"
    echo "✅ Trash cleaner removed."
    exit 0
fi

mkdir -p "$SCRIPT_DIR"

curl -s -o "$SCRIPT_PATH" https://raw.githubusercontent.com/rickvanderwolk/macos-auto-cleaners/main/empty_trash.sh
chmod +x "$SCRIPT_PATH"

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
        <string>$SCRIPT_PATH</string>
    </array>

    <key>StartInterval</key>
    <integer>86400</integer>

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

echo "✅ Installed LaunchAgent for automatic trash cleaning (every minute)."
echo "🚀 Running first cleanup now..."
"$SCRIPT_PATH"
