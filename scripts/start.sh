#!/usr/bin/env bash
set -exuo pipefail
FILE="/test/umbrel/events/signals/reboot"
if [ -f "$FILE" ]; then
 if grep -Fxq "true" "$FILE"
 then
    sed -i "\$d" "$FILE"
    echo rebooting 
   /test/umbrel/scripts/app start installed;
 else
    echo starting
   /test/umbrel/scripts/start;
 fi
fi
