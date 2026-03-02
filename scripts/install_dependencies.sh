#!/bin/bash
echo "=== Installing Dependencies ==="
if ! java -version 2>&1 | grep "17"; then
    apt-get update -y
    apt-get install -y openjdk-17-jdk
fi
mkdir -p /opt/petclinic
mkdir -p /var/log/petclinic
echo "=== Done ==="