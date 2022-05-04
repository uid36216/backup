#!/bin/bash

[ $# -eq 0 ] && {
    echo "usage: bash speed.sh [ifname]"
    exit
}

ifname=$1
line=$(ifconfig | grep mtu | grep --color=none -n $ifname)
[ $? -eq 0 ] || {
    echo "ifname \"$ifname\" not found!"
    exit
}
ifid=${line::1}

x1=
x2=
y1=
y2=

while true; do
    x1=$x2
    x2=$(ifconfig | grep "RX packets" | sed -n ${ifid}p | awk '{print $5}')
    #echo "x1=$x1 x2=$x2"
    y1=$y2
    y2=$(ifconfig | grep "TX packets" | sed -n ${ifid}p | awk '{print $5}')
    #echo "y1=$y1 y2=$y2"
    sleep 1
    [ -z "$x1" ] || {
        clear
        dl=$(echo "($x2-$x1)/1024" | bc)
        ul=$(echo "($y2-$y1)/1024" | bc)
        echo "DL: ${dl}KB/s UL: ${ul}KB/s"
    }
done
