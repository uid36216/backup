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
    line=$(ifconfig $ifname)
    x1=$x2
    x2=$(echo "$line" | grep "RX packets" | awk '{print $5}')
    #echo "x1=$x1 x2=$x2"
    y1=$y2
    y2=$(echo "$line" | grep "TX packets" | awk '{print $5}')
    #echo "y1=$y1 y2=$y2"
    [ -z "$x1" ] || {
        clear
        #dl=$(echo "($x2-$x1)/1024" | bc)
        #ul=$(echo "($y2-$y1)/1024" | bc)
        dl=$(expr $x2 - $x1)
        dl=$(expr $dl / 1024)
        ul=$(expr $y2 - $y1)
        ul=$(expr $ul / 1024)
        dl_cnt=$(echo "$line" | grep "RX packets" | awk '{print $6,$7}' | sed "s/(//g;s/)//g")
        ul_cnt=$(echo "$line" | grep "TX packets" | awk '{print $6,$7}' | sed "s/(//g;s/)//g")
        echo "DL: ${dl}KB/s $dl_cnt"
        echo "UL: ${ul}KB/s $ul_cnt"
    }
    sleep 1
done
