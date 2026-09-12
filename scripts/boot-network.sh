#!/bin/bash
sleep 5
sysctl --system >/dev/null 2>&1
iptables-restore < /etc/iptables/rules.v4 2>/dev/null
# GARANTIZAR puertos de emergencia SIEMPRE abiertos tras restore
for _p in 22 54321 8012; do
    iptables -C INPUT -p tcp --dport "$_p" -j ACCEPT 2>/dev/null || \
        iptables -I INPUT 1 -p tcp --dport "$_p" -j ACCEPT 2>/dev/null
done
# Si el INPUT policy es DROP y no hay reglas ACCEPT, abrir todo temporalmente
_RULES_COUNT=$(iptables -L INPUT -n 2>/dev/null | grep -c "ACCEPT")
if [[ "$_RULES_COUNT" -lt 3 ]]; then
    iptables -P INPUT ACCEPT 2>/dev/null
fi
iptables-save > /etc/iptables/rules.v4 2>/dev/null
# GARANTIZAR que SSH escuche en puertos 22 + 54321 + 8012
if [[ -f /etc/ssh/sshd_config.d/ports-movivip.conf ]]; then
    systemctl is-active ssh >/dev/null 2>&1 || systemctl restart ssh 2>/dev/null
fi
IFACE=$(ip route get 8.8.8.8 2>/dev/null | awk '{for(i=1;i<=NF;i++) if($i=="dev"){print $(i+1); exit}}')
[[ -z "$IFACE" ]] && IFACE=$(ls /sys/class/net | grep -E '^(eth|ens|enp)' | head -n1)
[[ -z "$IFACE" ]] && IFACE=eth0
ip link set dev "$IFACE" mtu 1470 2>/dev/null
tc qdisc del dev "$IFACE" root 2>/dev/null
tc qdisc add dev "$IFACE" root fq 2>/dev/null
modprobe tcp_bbr 2>/dev/null
