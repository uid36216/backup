#!/bin/bash

foo() {
  port=$1
  max=$2
  chain=conn-limit-port-$port

  iptables -vL -n | grep "Chain $chain" -q || {
    iptables -N $chain
  }

  iptables -vL INPUT -n | grep "$chain" -q || {
    iptables -A INPUT -j $chain
  }

  iptables -F $chain
  readarray -t arr < <(grep :$port | grep "ESTABLISHED" | sed -e "s/^.*->\(.*\):.*$/\1/g" | sort -n | uniq)

  cnt=${#arr[@]}
  if [ $cnt -ge $max ]; then
    iptables -vL $chain -n | grep "DROP" -q && {
      # already limited, skip
      return
    }
    # allow top $max IPs
    echo "$port: $cnt/$max [${arr[@]}]"
    iptables -F $chain
    iptables -A $chain -s 127.0.0.1 -j ACCEPT
    iptables -A $chain -m state --state ESTABLISHED,RELATED -j ACCEPT
    for i in $(seq 0 `expr $max - 1`); do
      iptables -A $chain -p tcp --dport $port -s "${arr[$i]}" -j ACCEPT
    done
    iptables -A $chain -p tcp --dport $port -j DROP
  else
    # allow all IPs
    echo "$port: $cnt/$max [${arr[@]}]"
    iptables -F $chain
  fi
}

##################################################################

while true; do
  clear
  lsof_str=$(lsof -i -n -P)
  # echo "$lsof_str" | foo [port] [max]
  echo "$lsof_str" | foo 6666 1
  sleep 1
done
