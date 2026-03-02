#!/bin/bash
echo "=== Starting Application ==="
APP_DIR="/opt/petclinic"
LOG_FILE="/var/log/petclinic/app.log"
JAR_FILE=$(ls $APP_DIR/*.jar | head -1)

nohup java \
  -XX:+UseContainerSupport \
  -XX:MaxRAMPercentage=75.0 \
  -Djava.security.egd=file:/dev/./urandom \
  -jar "$JAR_FILE" \
  > "$LOG_FILE" 2>&1 &

echo $! > /opt/petclinic/app.pid
echo "Started with PID: $(cat /opt/petclinic/app.pid)"