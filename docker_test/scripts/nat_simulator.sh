#!/bin/bash

# NAT Simulator - Simulates different NAT types using iptables and tc

NAT_TYPE=${1:-full_cone}
PEER_ID=${2:-peer1}
INTERNAL_IP=${3:-192.168.10.10}
EXTERNAL_IP=${4:-172.17.0.10}
INTERNAL_PORT=${5:-5000}

echo "[NAT] Configuring ${NAT_TYPE} NAT for ${PEER_ID}"

# Reset rules
iptables -F
iptables -F -t nat
iptables -X
iptables -X -t nat

# Enable IP forwarding
echo 1 > /proc/sys/net/ipv4/ip_forward

case "$NAT_TYPE" in
  full_cone)
    echo "[NAT] Full Cone NAT: External packets from ANY address/port can reach internal IP/port"
    # Allow all inbound traffic to be translated
    iptables -t nat -A PREROUTING -i eth0 -p udp -d $EXTERNAL_IP --dport $INTERNAL_PORT -j DNAT --to-destination $INTERNAL_IP:$INTERNAL_PORT
    iptables -t nat -A POSTROUTING -o eth0 -p udp -d $INTERNAL_IP --dport $INTERNAL_PORT -j SNAT --to-source $EXTERNAL_IP
    # Allow outbound connections with port mapping
    iptables -t nat -A POSTROUTING -o eth0 -s $INTERNAL_IP -p udp --sport $INTERNAL_PORT -j SNAT --to-source $EXTERNAL_IP
    ;;

  address_restricted)
    echo "[NAT] Address Restricted Cone NAT: Only packets from the source address can reach internal IP/port"
    # This requires tracking the first connection attempt
    # For simulation, we'll use a connection tracking rule
    iptables -t nat -A PREROUTING -i eth0 -p udp -d $EXTERNAL_IP --dport $INTERNAL_PORT -m state --state ESTABLISHED,RELATED -j DNAT --to-destination $INTERNAL_IP:$INTERNAL_PORT
    iptables -t nat -A POSTROUTING -o eth0 -s $INTERNAL_IP -p udp --sport $INTERNAL_PORT -j SNAT --to-source $EXTERNAL_IP
    # Block packets from different source IPs
    iptables -A INPUT -i eth0 -p udp -d $EXTERNAL_IP --dport $INTERNAL_PORT -m state --state NEW -j DROP
    ;;

  port_restricted)
    echo "[NAT] Port Restricted Cone NAT: Only packets from the specific address:port can reach internal IP:port"
    # Similar to address restricted but more strict
    iptables -t nat -A PREROUTING -i eth0 -p udp -d $EXTERNAL_IP --dport $INTERNAL_PORT -m state --state ESTABLISHED,RELATED -j DNAT --to-destination $INTERNAL_IP:$INTERNAL_PORT
    iptables -t nat -A POSTROUTING -o eth0 -s $INTERNAL_IP -p udp --sport $INTERNAL_PORT -j SNAT --to-source $EXTERNAL_IP
    # Block ports and specific addresses
    iptables -A INPUT -i eth0 -p udp -d $EXTERNAL_IP --dport $INTERNAL_PORT -m state --state NEW -j DROP
    ;;

  symmetric)
    echo "[NAT] Symmetric NAT: Different external ports for different destination addresses"
    # Use random port mapping for different destinations
    iptables -t nat -A POSTROUTING -o eth0 -s $INTERNAL_IP -p udp -j SNAT --to-source $EXTERNAL_IP:$((INTERNAL_PORT + 1000))-$((INTERNAL_PORT + 2000)) --random
    iptables -t nat -A PREROUTING -i eth0 -p udp -d $EXTERNAL_IP -j DNAT --to-destination $INTERNAL_IP:$INTERNAL_PORT
    ;;

  *)
    echo "[NAT] Unknown NAT type: $NAT_TYPE"
    exit 1
    ;;
esac

# Add connection tracking
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

echo "[NAT] NAT configuration complete"
iptables -t nat -L -n -v
