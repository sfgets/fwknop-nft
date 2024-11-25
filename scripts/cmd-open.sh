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
alias nlcs='$n list chains'
alias nalc='$n -a list chain inet fw4'
alias ncc='$n create chain inet fw4'
alias nlc='$n list chain inet fw4'
alias nir='$n insert rule inet fw4'

WANCHAIN="input_wan"
WANFINALRULE="drop_from_wan"
DEFAULTCHAIN="input_fwknop"

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
  *) PROTO=tcp
esac

# Handle missing chain. New chain will be created with a simple return statement.
# Additional rules should be inserted 
if ! nlcs | grep "$DEFAULTCHAIN" > /dev/null; then
  ncc "$DEFAULTCHAIN"
  nir "$DEFAULTCHAIN" return
fi

# Handle redirect and processing to fwknop chain 
if ! nlc "$WANCHAIN" | grep "$DEFAULTCHAIN" > /dev/null ; then
  pos=$(nalc "$WANCHAIN" | grep "$WANFINALRULE" | cut -d'#' -f2 | cut -d' ' -f3)
  echo "insert a jump rule on position $pos"
  nir "$WANCHAIN" position "$pos" jump "$DEFAULTCHAIN"
  nir "$DEFAULTCHAIN" ip saddr "$IP" "$PROTO" dport "$PORT" accept
else
  nir "$DEFAULTCHAIN" ip saddr "$IP" "$PROTO" dport "$PORT" accept
fi