#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 ]]; then
    echo "Usage: $0 <package1> [package2] [package3] ..." >&2
    echo "Example: $0 kubeadm kubelet kubectl" >&2
    exit 1
fi

PKGS=("$@")
declare -A LATEST

for pkg in "${PKGS[@]}"; do
    ver=$(apt-cache madison "$pkg" | awk '{print $3}' | sort -V | tail -n1)
    if [[ -z "$ver" ]]; then
        echo "Could not find any version for $pkg — check your apt sources" >&2
        exit 1
    fi
    LATEST[$pkg]=$ver
    echo "$pkg latest available: $ver"
done

LOWEST=$(printf '%s\n' "${LATEST[@]}" | sort -V | head -n1)
echo "Pinning all ${#PKGS[@]} package(s) to: $LOWEST"

INSTALL_ARGS=()
for pkg in "${PKGS[@]}"; do
    INSTALL_ARGS+=("${pkg}=${LOWEST}")
done

sudo apt-get install -y "${INSTALL_ARGS[@]}"
sudo apt-mark hold "${PKGS[@]}"