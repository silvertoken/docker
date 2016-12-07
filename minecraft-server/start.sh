#!/bin/sh

set -e
usermod --uid $UID minecraft
groupmod --gid $GID minecraft

chown -R minecraft:minecraft /opt/minecraft/data /opt/minecraft/start-minecraft
chmod -R g+wX /opt/minecraft/data /opt/minecraft/start-minecraft

while lsof -- /opt/minecraft/start-minecraft; do
  echo -n "."
  sleep 1
done

mkdir -p /home/minecraft
chown minecraft: /home/minecraft

echo "Starting cron"
exec crond

echo "Switching to user 'minecraft'"
exec sudo -E -u minecraft /opt/minecraft/start-minecraft "$@"
