#!/bin/bash

foo() {
  port=$1
  max=$2
  [ -z "$max" ] && max=1
  chain=conn-limit-port-$port

  readarray -t arr < <(grep ":$port->" | grep "ESTABLISHED" | sed -e "s/^.*->\(.*\):.*$/\1/g" | sort -n | uniq)
  cnt=${#arr[@]}
  echo "$port: $cnt/$max [${arr[@]}]"
  
  if [ $cnt -ge $max ]; then
    iptables -vL $chain -n | grep "DROP" -q && {
      # already limited, skip
      return
    }
    # allow top $max IPs
    iptables -F $chain
    iptables -A $chain -s 127.0.0.1 -j ACCEPT
    iptables -A $chain -m state --state ESTABLISHED,RELATED -j ACCEPT
    for i in $(seq 0 `expr $max - 1`); do
      iptables -A $chain -p tcp --dport $port -s "${arr[$i]}" -j ACCEPT
    done
    iptables -A $chain -p tcp --dport $port -j DROP
  else
    # allow all IPs
    iptables -F $chain
  fi
}

ipt_setup() {
  port=$1
  chain=conn-limit-port-$port
  iptables -vL -n | grep "Chain $chain" -q || {
    iptables -N $chain
  }

  iptables -vL INPUT -n | grep "$chain" -q || {
    iptables -A INPUT -j $chain
  }

  iptables -F $chain
}

finally() {
  echo "bye"
  readarray -t arr < <(iptables -vL -n  | grep "Chain conn-limit-port" | sed -e "s/^Chain \(.*\) (.*)$/\1/g")
  for i in ${arr[@]}; do
    iptables -D INPUT -j $i 2>/dev/null
    iptables -X $i 2>/dev/null
  done
}

##################################################################

trap finally EXIT

[ $# -eq 0 ] && exit

for s in $*; do
  params=$(echo $s | sed "s/,/ /g")
  ipt_setup $params
done 

while true; do
  clear
  lsof_str=$(lsof -i -n -P)
  for s in $*; do
    params=$(echo $s | sed "s/,/ /g")
    echo "$lsof_str" | foo $params
  done
  sleep 1
done
