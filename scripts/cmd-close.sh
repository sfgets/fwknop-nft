#!/bin/sh
#Copyright (C) [2014] [Kamen Medarski]
#This program is free software; you can redistribute it and/or modify
#it under the terms of the GNU General Public License as published by
#the Free Software Foundation; version 2.
#This program is distributed in the hope that it will be useful,
#but WITHOUT ANY WARRANTY; without even the implied warranty of
#MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
#GNU General Public License for more details.

n='nft'

#DRY commands
alias nalc='$n -a list chain inet fw4'
alias ndr='$n delete rule inet fw4'


DEFAULTCHAIN="input_fwknop"

handle() {
    nalc "$DEFAULTCHAIN" | grep "$1" | grep "$2" | grep "$3" | cut -d'#' -f2 | cut -d' ' -f3 | xargs
}
case $1 in
    [0-9]*.[0-9]*.[0-9]*.[0-9]*) IP=$1;;
    *) echo "Invalid IP address $1";;
esac

case $2 in
    [0-9]*) PORT=$2;;
    *) echo "Invalid port $2";;
esac

case $3 in
  17) PROTO=udp;;
  *) PROTO=tcp;;
esac

hand="$(handle "$IP" "$PORT" "$PROTO")"
set -- "$hand"
for i in $@; do
    if [ "x$i" != "x" ]; then 
        ndr "$DEFAULTCHAIN" handle "$i"
    else
        echo "Rule with params: ip::$IP port::$PORT proto::$PROTO Not found"
    fi
done