#!/bin/bash

NB=100
PORT=3306
HOST="xxx.rds.amazonaws.com"

i=1
sum_ms=0
max_ms=0
min_ms=1000.0
while [ $i -le $NB ]; do
    latency=`nmap -Pn $HOST -p $PORT |grep latency | awk -F' ' '{ print $4 }' | sed -e 's#s##' -e 's#(##'`
    latency_ms=`echo "1000 * $latency" | bc -l`
    sum_ms=`echo $sum_ms + $latency_ms | bc`
    if (( $(echo "$latency_ms > $max_ms" |bc -l) )); then max_ms=$latency_ms; fi
    if (( $(echo "$latency_ms < $min_ms" |bc -l) )); then min_ms=$latency_ms; fi
    #echo "latency = $latency_ms     min = $min_ms     max = $max_ms    sum = $sum_ms"
    i=$((i+1))
done
avg_latency_ms=`echo "scale=2;$sum_ms / $NB" | bc`
echo "Average latency = $avg_latency_ms ms"
echo "Minimun latency = $min_ms ms"
echo "Maximum latency = $max_ms ms"
