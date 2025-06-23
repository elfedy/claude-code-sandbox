#!/bin/bash
set -euo pipefail

# Flush existing rules
iptables -F
iptables -X
iptables -Z

# Flush IPv6 rules
ip6tables -F
ip6tables -X
ip6tables -Z

# Destroy existing ipsets
ipset list -n 2>/dev/null | while read -r set; do
    ipset destroy "$set" 2>/dev/null || true
done

# Allow DNS queries (UDP port 53)
iptables -A OUTPUT -p udp --dport 53 -j ACCEPT
iptables -A INPUT -p udp --sport 53 -j ACCEPT

# Allow SSH connections (for remote development)
iptables -A OUTPUT -p tcp --dport 22 -j ACCEPT
iptables -A INPUT -p tcp --sport 22 -j ACCEPT

# Allow all traffic on localhost interfaces
iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT

# Create ipset for allowed domains
ipset create allowed-domains hash:net family inet hashsize 1024 maxelem 65536

# Function to add IP ranges to ipset
add_ips() {
    local ips="$1"
    while IFS= read -r ip; do
        if [[ -n "$ip" && "$ip" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+(/[0-9]+)?$ ]]; then
            ipset add allowed-domains "$ip" 2>/dev/null || true
        fi
    done <<< "$ips"
}

# Add GitHub IP ranges
echo "Adding GitHub IP ranges..."
GITHUB_META=$(curl -s https://api.github.com/meta || echo '{}')
GITHUB_WEB=$(echo "$GITHUB_META" | jq -r '.web[]?' 2>/dev/null || true)
GITHUB_API=$(echo "$GITHUB_META" | jq -r '.api[]?' 2>/dev/null || true)
GITHUB_GIT=$(echo "$GITHUB_META" | jq -r '.git[]?' 2>/dev/null || true)

add_ips "$GITHUB_WEB"
add_ips "$GITHUB_API"
add_ips "$GITHUB_GIT"

# Function to resolve and add domain IPs
resolve_and_add() {
    local domain="$1"
    echo "Resolving $domain..."
    local ips=$(dig +short "$domain" A | grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$' || true)
    if [[ -n "$ips" ]]; then
        while IFS= read -r ip; do
            echo "  Adding $ip"
            ipset add allowed-domains "$ip/32" 2>/dev/null || true
        done <<< "$ips"
    fi
}

# Add specific allowed domains
ALLOWED_DOMAINS=(
    "registry.npmjs.org"
    "api.anthropic.com"
    "sentry.io"
    "*.sentry.io"
    "statsig.anthropic.com"
    "statsig.com"
    "api.statsig.com"
)

# Add custom ANTHROPIC_BASE_URL if set
if [[ -n "${ANTHROPIC_BASE_URL:-}" ]]; then
    # Extract domain from URL
    custom_domain=$(echo "$ANTHROPIC_BASE_URL" | sed -E 's|^https?://([^/]+).*$|\1|')
    if [[ -n "$custom_domain" ]]; then
        echo "Adding Anthropic base url: $custom_domain"
        ALLOWED_DOMAINS+=("$custom_domain")
    fi
fi

for domain in "${ALLOWED_DOMAINS[@]}"; do
    # Handle wildcards by resolving base domain
    if [[ "$domain" == *"*"* ]]; then
        base_domain="${domain#*.}"
        resolve_and_add "$base_domain"
    else
        resolve_and_add "$domain"
    fi
done

# Detect host network interface
HOST_IFACE=$(ip route | grep default | awk '{print $5}' | head -n1)
if [[ -n "$HOST_IFACE" ]]; then
    echo "Detected host interface: $HOST_IFACE"
    # Get host network
    HOST_NET=$(ip -4 addr show "$HOST_IFACE" | grep -oP '(?<=inet\s)\d+\.\d+\.\d+\.\d+/\d+' | head -n1)
    if [[ -n "$HOST_NET" ]]; then
        echo "Adding host network $HOST_NET to allowed domains"
        ipset add allowed-domains "$HOST_NET" 2>/dev/null || true
    fi
fi

# Set default policies to DROP
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT DROP

# Allow established and related connections
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# Allow output to allowed domains
iptables -A OUTPUT -m set --match-set allowed-domains dst -j ACCEPT

# IPv6: Block all by default
ip6tables -P INPUT DROP
ip6tables -P FORWARD DROP
ip6tables -P OUTPUT DROP
ip6tables -A INPUT -i lo -j ACCEPT
ip6tables -A OUTPUT -o lo -j ACCEPT

echo "Firewall rules applied successfully"

# Verify firewall is working
echo "Testing firewall..."

# Test allowed domain
if curl -s --max-time 5 https://api.github.com/rate_limit >/dev/null 2>&1; then
    echo "✓ GitHub API accessible (expected)"
else
    echo "✗ GitHub API not accessible (unexpected)"
fi

# Test blocked domain
if curl -s --max-time 5 https://example.com >/dev/null 2>&1; then
    echo "✗ External domains accessible (firewall may not be working)"
    exit 1
else
    echo "✓ External domains blocked (expected)"
fi

echo "Firewall initialization complete"
