#!/bin/bash
set -e

mkdir -p /run/sshd /home/codex/.ssh
if [ -f /ssh/authorized_keys ]; then
    cp /ssh/authorized_keys /home/codex/.ssh/authorized_keys
fi
chmod 700 /home/codex/.ssh
chmod 600 /home/codex/.ssh/authorized_keys 2>/dev/null || true
chown -R codex:codex /home/codex

# Ensure codex account is unlocked for ssh key auth
usermod -p '*' codex 2>/dev/null || true
echo "cd /workspace" >> /home/codex/.bashrc
echo "cd /workspace" >> /home/codex/.profile


ssh-keygen -A >/dev/null 2>&1
/usr/sbin/sshd

echo "CSAPP Docker SSH environment ready on port 22."
exec tail -f /dev/null
