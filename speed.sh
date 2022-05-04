#!/bin/bash

command -v ifconfig &>/dev/null || {
    echo "ifconfig not found"
    exit
}

[ $# -eq 0 ] && {
    echo "usage: bash speed.sh [ifname]"
    exit
}

ifname=$1
ifconfig | grep -q $ifname || {
    echo "ifname \"$ifname\" not found"
    exit
}

x1=
x2=
y1=
y2=

while true; do
    x1=$x2
    x2=$(ifconfig $ifname | grep "RX packets" | awk '{print $5}')
    #echo "x1=$x1 x2=$x2"
    y1=$y2
    y2=$(ifconfig $ifname | grep "TX packets" | awk '{print $5}')
    #echo "y1=$y1 y2=$y2"
    sleep 1
    [ -z "$x1" ] || {
        clear
        dl=$(echo "($x2-$x1)/1024" | bc)
        ul=$(echo "($y2-$y1)/1024" | bc)
        echo "DL: ${dl}KB/s UL: ${ul}KB/s"
    }
done
