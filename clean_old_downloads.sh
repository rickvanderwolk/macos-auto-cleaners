#!/bin/bash

DOWNLOADS="$HOME/Downloads"
DAYS=7

echo "🧹 Checking for files older than $DAYS days in $DOWNLOADS..."

find "$DOWNLOADS" -type f -mtime +$DAYS -print -delete 2>/dev/null

echo "✅ Downloads cleanup completed at $(date)"
