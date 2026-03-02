#!/bin/bash
echo "=== Stopping Application ==="
APP_PID=$(pgrep -f "spring-petclinic" || true)
if [ -n "$APP_PID" ]; then
    kill -15 $APP_PID
    sleep 5
    kill -9 $APP_PID 2>/dev/null || true
    echo "Application stopped"
else
    echo "No running application found"
fi