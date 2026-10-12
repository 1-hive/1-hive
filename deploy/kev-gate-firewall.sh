#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
# Lets vm2 reach only kev-gate (tcp 8010) on this host over Tailscale, and nothing else.
#
# A Tailscale node share makes every port of this host reachable from the sharee's device
# (sshd, any game published on the Tailscale address). This drops all of vm2's traffic on
# tailscale0 except kev-gate. Run as root, with vm2's Tailscale addresses (see `tailscale
# status` once the share is accepted):
#
#   sudo deploy/kev-gate-firewall.sh 100.x.y.z fd7a:115c:a1e0::xxxx
#
# It writes /etc/nftables-kevgate.nft and a oneshot unit that loads it at boot, after
# tailscaled. Undo: sudo systemctl disable --now kev-gate-firewall; sudo nft delete table inet kevgate
set -euo pipefail
[ "$(id -u)" = 0 ] || { echo "run as root (sudo)" >&2; exit 2; }
[ $# -ge 1 ] || { echo "usage: $0 VM2_IPV4 [VM2_IPV6]" >&2; exit 2; }
V4=$1; V6=${2:-}
python3 -c 'import ipaddress,sys; [ipaddress.ip_address(a) for a in sys.argv[1:]]' "$@"

{
  echo "table inet kevgate {"
  echo "  chain input {"
  echo "    type filter hook input priority -10; policy accept;"
  echo "    iifname \"tailscale0\" ip saddr $V4 tcp dport 8010 accept"
  echo "    iifname \"tailscale0\" ip saddr $V4 drop"
  if [ -n "$V6" ]; then
    echo "    iifname \"tailscale0\" ip6 saddr $V6 tcp dport 8010 accept"
    echo "    iifname \"tailscale0\" ip6 saddr $V6 drop"
  fi
  echo "  }"
  echo "}"
} > /etc/nftables-kevgate.nft

cat > /etc/systemd/system/kev-gate-firewall.service <<'EOF'
[Unit]
Description=Limit vm2 to kev-gate (tcp 8010) on tailscale0 (1-hive deploy/kev-gate-firewall.sh)
After=tailscaled.service
Wants=tailscaled.service

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStartPre=-/usr/sbin/nft delete table inet kevgate
ExecStart=/usr/sbin/nft -f /etc/nftables-kevgate.nft
ExecStop=/usr/sbin/nft delete table inet kevgate

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable --now kev-gate-firewall.service
systemctl restart kev-gate-firewall.service
nft list table inet kevgate
