#!/bin/bash
# Multi-distro cleanup
if command -v apt-get >/dev/null 2>&1; then apt clean 2>/dev/null; apt autoremove -y 2>/dev/null
elif command -v dnf >/dev/null 2>&1; then dnf clean all 2>/dev/null; dnf autoremove -y 2>/dev/null
elif command -v zypper >/dev/null 2>&1; then zypper clean 2>/dev/null
elif command -v pacman >/dev/null 2>&1; then pacman -Scc --noconfirm 2>/dev/null
fi
find /var/log -name '*.log.*' -mmin +1440 -delete 2>/dev/null
find /var/log -name '*.gz' -delete 2>/dev/null
find /tmp -type f -mmin +1440 -delete 2>/dev/null
find /var/tmp -type f -mmin +1440 -delete 2>/dev/null
journalctl --vacuum-time=1d 2>/dev/null
rm -rf /root/.cache/pip 2>/dev/null /root/.cache/apt 2>/dev/null
SWAP_USED=$(free | awk '/Swap/{print $3}')
if [[ "$SWAP_USED" -eq 0 ]]; then swapoff -a 2>/dev/null; swapon -a 2>/dev/null; fi
df -h / | awk 'NR==2 {print "[Auto-Cleanup] "$4" libre ("$5" usado)"}' >> /var/log/movivip-cleanup.log 2>/dev/null
