#!/bin/bash



cd `dirname $0`

echo "" > sclang.log

jackd -P95 -dalsa -dhw:1 -n3 -p512 &
pid1=$!
python server.py &
pid2=$!
sclang init.scd &> sclang.log
kill -15 $pid1 $pid2
