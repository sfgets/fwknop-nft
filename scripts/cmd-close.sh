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

nft_list()   { $NFT -a list chain inet fw4 "$1"; }
nft_delete() { $NFT delete rule inet fw4 "$@"; }

log() { echo "$*" >&2; }

# --- Core ---

get_handles() {
    local ip="$1" port="$2" proto="$3"
    nft_list "$DEFAULTCHAIN" \
        | grep "$ip" | grep "$port" | grep "$proto" \
        | cut -d'#' -f2 | awk '{print $2}'
}

delete_rules() {
    local ip="$1" port="$2" proto="$3"
    local found=0

    for handle in $(get_handles "$ip" "$port" "$proto"); do
        log "Deleting handle $handle ($ip $proto $port)"
        nft_delete "$DEFAULTCHAIN" handle "$handle"
        found=1
    done

    [ "$found" -eq 0 ] && \
        log "Rule not found: ip=$ip port=$port proto=$proto"
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
}

# --- Main ---

main() {
    parse_args "$@"
    delete_rules "$IP" "$PORT" "$PROTO"
}

main "$@"
