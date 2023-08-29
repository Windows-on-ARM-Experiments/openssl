#!/bin/bash

first_benchmark=$1
second_benchmark=$2

cat $first_benchmark | grep "^Doing" | sed -E "s/[ \r]+$//" > b1.txt
cat $second_benchmark | grep "^Doing" | sed -E "s/[ \r]+$//" > b2.txt
paste b1.txt b2.txt | awk '{match($0, /(^[^:]+)/, g1); match($0, /\t+(Doing[^:]+)/, g2); if (g1[1] != g2[1]) exit -1}' \
    || { echo "Benchmark test sets are not identical"; rm b1.txt b2.txt; exit -1; } 
cat b2.txt | sed -E "s/^[^:]+: /\/\t/" | sed -E "s/ .* / /" > b2_1.txt
paste b1.txt b2_1.txt | awk '{match($0, /: ([0-9]+)/, g1); match($0, /([\.0-9]+)s\t\//, g2); match($0, /\/\t([0-9]+) /, g3); match($0, /([\.0-9]+)s$/, g4); printf "%f %s\n", (g3[1] / g4[1]) / (g1[1] / g2[1]), $0}'
rm b1.txt b2.txt b2_1.txt
