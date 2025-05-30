#!/bin/bash

SCRIPT_DIR="$HOME/scripts"
SCRIPT_PATH="$SCRIPT_DIR/clean_old_downloads.sh"
WRAPPER_PATH="$SCRIPT_DIR/run_downloads_via_terminal.sh"
PLIST="$HOME/Library/LaunchAgents/com.user.downloadscleaner.plist"
LABEL="com.user.downloadscleaner"

if [[ "$1" == "--uninstall" ]]; then
    echo "🧹 Uninstalling downloads cleaner..."
    launchctl bootout gui/$(id -u) "$PLIST" 2>/dev/null
    rm -f "$PLIST" "$SCRIPT_PATH" "$WRAPPER_PATH"
    echo "✅ Downloads cleaner removed."
    exit 0
fi

mkdir -p "$SCRIPT_DIR"

curl -s -o "$SCRIPT_PATH" https://raw.githubusercontent.com/rickvanderwolk/macos-auto-cleaners/main/clean_old_downloads.sh
chmod +x "$SCRIPT_PATH"

cat <<EOF > "$WRAPPER_PATH"
#!/bin/bash
osascript <<APPLESCRIPT
tell application "Terminal"
    do script "bash '$SCRIPT_PATH'; exit"
    delay 2
    try
        close front window
    end try
end tell
APPLESCRIPT
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
    <integer>86400</integer>

    <key>RunAtLoad</key>
    <true/>

    <key>StandardOutPath</key>
    <string>/tmp/downloadscleaner.out</string>
    <key>StandardErrorPath</key>
    <string>/tmp/downloadscleaner.err</string>
</dict>
</plist>
EOF

launchctl bootout gui/$(id -u) "$PLIST" 2>/dev/null
launchctl bootstrap gui/$(id -u) "$PLIST"

echo "✅ Installed LaunchAgent for cleaning Downloads folder (daily)."
echo "🛡️  Make sure Terminal has Full Disk Access:"
echo "   System Settings → Privacy & Security → Full Disk Access → Add Terminal"
echo "🚀 Running first cleanup via Terminal..."
open -a Terminal "$SCRIPT_PATH"
