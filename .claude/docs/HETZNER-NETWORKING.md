# Hetzner Networking Reference

## IP/MAC Binding

Hetzner enforces strict IP/MAC binding on all dedicated servers. Traffic with
unrecognized source MAC addresses is flagged as abuse and may result in server
blocking.

**Implications:**
- Bridged VM setups require **virtual MAC addresses** from Robot Panel.
- Routed setups (no bridge-ports on physical interface) avoid this issue.
- NAT/masquerading is the safest default for internal VMs.

## Network Topologies

### Routed Setup (Recommended for single-IP servers)
- Physical interface gets the main IP with `/32` mask.
- `vmbr0` bridge has `bridge-ports none` and serves as gateway for VMs.
- Additional IPs require explicit `ip route add` on the bridge.
- Each additional IP is treated as its own `/32` network entity.

### Bridged Setup (Requires virtual MACs)
- Physical interface set to `manual`.
- `vmbr0` bridge has `bridge-ports <physical-iface>`.
- VMs get their own public IPs with virtual MAC addresses.
- DHCP can be used if virtual MAC is configured.

### NAT/Masquerading (Default for this installer)
- Physical interface or `vmbr0` gets the public IP.
- `vmbr1` bridge with private subnet (e.g., `192.168.26.0/24`).
- iptables MASQUERADE rule on `vmbr1` for outbound traffic.
- Optional DNAT/PREROUTING for inbound port forwarding.

## Interface Naming

### In Rescue System
- Always `eth0` (or similar legacy name).
- Real interface name differs after Proxmox install.

### Discovering Real Names
```bash
# Hetzner's predict-check tool
predict-check
# Output: eth0 -> enp0s31f6

# Hetzner's netdata tool
netdata
# Shows: link status, MAC, IP, driver info
```

### Common Hetzner Interface Names
| Server Series | Typical Interface |
|---------------|-------------------|
| AX series     | `enp0s31f6`, `eno1`, `enp35s0` |
| EX series     | `enp0s31f6`, `eno1` |
| SX series     | `eno1`, `enp0s31f6` |

## IPv6 on Hetzner

- Every server gets a `/64` IPv6 subnet.
- Gateway is always `fe80::1`.
- Main interface should use `/128` on the interface, `/64` on the bridge.
- Example: `2001:db8::2/128` on interface, `2001:db8::3/64` on `vmbr0`.

## Firewall Considerations

- Default Hetzner install has **no firewall**.
- Port 8006 (Proxmox Web UI) and 22 (SSH) are directly exposed.
- Recommended: `iptables-persistent` or Proxmox's built-in firewall.
- `nf_conntrack` module needed for stateful firewall rules.

## DNS Resolvers

Hetzner provides these DNS servers:
- `185.12.64.1` (primary)
- `185.12.64.2` (secondary)

Alternatives: `1.1.1.1` (Cloudflare), `8.8.8.8` (Google), `9.9.9.9` (Quad9).

## Example /etc/network/interfaces (NAT Setup)

```
auto lo
iface lo inet loopback

iface <IFACE> inet manual

auto vmbr0
iface vmbr0 inet static
    address <PUBLIC_IP>/32
    gateway <GATEWAY>
    bridge-ports <IFACE>
    bridge-stp off
    bridge-fd 1
    pointopoint <GATEWAY>

iface vmbr0 inet6 static
    address <IPV6>/128
    gateway fe80::1

auto vmbr1
iface vmbr1 inet static
    address <PRIVATE_IP>/24
    bridge-ports none
    bridge-stp off
    bridge-fd 0
    post-up   iptables -t nat -A POSTROUTING -s '<PRIVATE_SUBNET>' -o vmbr0 -j MASQUERADE
    post-down iptables -t nat -D POSTROUTING -s '<PRIVATE_SUBNET>' -o vmbr0 -j MASQUERADE
```
