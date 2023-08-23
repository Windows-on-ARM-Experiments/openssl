#!/bin/bash

[ ! -d .github/workflows/data/benchmark_snapshot ] && mkdir -p .github/workflows/data/benchmark_snapshot
branch=$(git symbolic-ref --short HEAD)
benchmark_snapshot=$(date +".github/workflows/data/benchmark_snapshot/${branch}_%Y-%m-%d_%H_%M_%S.txt")
.github/workflows/scripts/benchmark_cmp.sh benchmark_aarch64_gcc.txt benchmark_aarch64_gcc.txt > $benchmark_snapshot || exit -1

chart_payload="cht=bvg&chs=500x375&chtt=Perfromance%20ratio%20comparision&chma=30,30,30,30&chdlp=t&chco=4d89f9,c6d9fd&chbh=r,0,0&chxt=x,x,y&chxl=1:|Benchmark%20test%20%23&chxp=1,50&chds=a&chxs=2N*p&chdl=AArch64%20/%20Arm64%20Windows&chxr=0,0,247,48&chd=t:"
chart_payload+=$(cat $benchmark_snapshot \
    | sort -n -r -k 1 \
    | awk '{val = $1; if (val >= 1) val -= 1; else val = -1/val + 1; printf "%f,", val}')
chart_payload="${chart_payload%?}"

curl -X POST -d "$chart_payload" https://chart.googleapis.com/chart > benchmark_snapshot.png
