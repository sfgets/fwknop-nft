#!/bin/sh

#Copyright (C) [2014] [Kamen Medarski]
#This program is free software; you can redistribute it and/or modify
#it under the terms of the GNU General Public License as published by
#the Free Software Foundation; version 2.
#This program is distributed in the hope that it will be useful,
#but WITHOUT ANY WARRANTY; without even the implied warranty of
#MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
#GNU General Public License for more details.

# --- Config ---
NFT="nft"
DEFAULTCHAIN="input_fwknop"

# --- Helpers ---

nft_list()   { $NFT -a  list chain inet fw4 "$1"; }
nft_listj()  { $NFT -ja list chain inet fw4 "$1"; }
nft_insert() { $NFT insert rule inet fw4 "$@"; }

log() { echo "$*" >&2; }

# --- Core functions ---

get_iface() {
    ip -j a | jq -r --arg v "$1" \
        '(.[] | select(any(.addr_info[]; .local == $v)) | .ifname) // "wan"'
}

get_chain() {
    nft_listj "input" | jq -r --arg v "$1" '
        .nftables[]
        | select(
            .rule.expr? as $expr
            | $expr and (any($expr[]; .match?["right"]? == $v))
          )
        | .rule.expr[1].jump.target? // empty
    '
}

get_first_rule_handle() {
    nft_listj "$1" | jq -r \
        '[.nftables[] | select(.rule)] | first | .rule.handle // empty'
}

chain_exists() {
    $NFT list chains | grep -q "$1"
}

chain_has_rule() {
    nft_list "$1" | grep -q "$2"
}

# Create fwknop chain with a return rule if not exists
ensure_chain() {
    if ! chain_exists "$DEFAULTCHAIN"; then
        log "Creating chain: $DEFAULTCHAIN"
        $NFT create chain inet fw4 "$DEFAULTCHAIN"
    fi
    if ! chain_has_rule "$DEFAULTCHAIN" "return"; then
        log "Adding return rule to $DEFAULTCHAIN"
        nft_insert "$DEFAULTCHAIN" return
    fi
}

# Insert jump to fwknop chain before first rule of target chain
ensure_jump() {
    local ch="$1"
    if ! chain_has_rule "$ch" "$DEFAULTCHAIN"; then
        local h
        h=$(get_first_rule_handle "$ch")
        log "Inserting jump to $DEFAULTCHAIN in chain $ch before handle $h"
        nft_insert "$ch" handle "$h" jump "$DEFAULTCHAIN"
    fi
}

# Add accept rule if not already present
ensure_accept_rule() {
    local ip="$1" proto="$2" port="$3"
    if ! chain_has_rule "$DEFAULTCHAIN" "$ip" | grep -q "$proto" | grep -q "$port"; then
        log "Adding rule: $ip $proto $port"
        nft_insert "$DEFAULTCHAIN" ip saddr "$ip" "$proto" dport "$port" accept
    fi
}

# --- Argument parsing ---

parse_args() {
    case "$1" in
        [0-9]*.[0-9]*.[0-9]*.[0-9]*) IP="$1" ;;
        *) log "Invalid IP: $1"; exit 1 ;;
    esac

    case "$2" in
        [0-9]*) PORT="$2" ;;
        *) log "Invalid port: $2"; exit 1 ;;
    esac

    case "$3" in
        17) PROTO="udp" ;;
        *)  PROTO="tcp" ;;
    esac

    case "$4" in
        *.*.*.*:*.*.*.*) SRC_IP="${4%:*}" ;;
        *) SRC_IP="$IP" ;;
    esac
}

# --- Main ---

main() {
    parse_args "$@"

    local iface ch
    iface=$(get_iface "$SRC_IP")
    ch=$(get_chain "$iface")

    log "Interface: $iface | Chain: $ch | IP: $IP | Proto: $PROTO | Port: $PORT"

    ensure_chain
    ensure_jump "$ch"
    ensure_accept_rule "$IP" "$PROTO" "$PORT"
}

main "$@"
/etc/fwknop/cmd-open.sh 149.62.208.23/etc/fwknop/cmd-open.sh 149.62.208.236 222 66 222 6