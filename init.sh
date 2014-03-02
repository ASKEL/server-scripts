#!/bin/bash

# Очистка цепочек правил
iptables -F INPUT
iptables -Z INPUT
iptables -P INPUT ACCEPT

iptables -F OUTPUT
iptables -Z OUTPUT
iptables -P OUTPUT ACCEPT

iptables -F FORWARD
iptables -Z FORWARD
iptables -P FORWARD ACCEPT

# Защита порта ssh, время блокировки - 30 секунд
iptables -A INPUT -p tcp -m state --state NEW --dport 22 -m recent --update --seconds 30 -j DROP
iptables -A INPUT -p tcp -m state --state NEW --dport 22 -m recent --set -j ACCEPT