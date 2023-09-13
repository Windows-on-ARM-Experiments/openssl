#!/bin/bash

execute_benchmark() {
    LD_LIBRARY_PATH=$(pwd) apps/openssl speed

    for i in sm3 sm4 aes-128-gcm aes-192-gcm aes-256-gcm; do
        LD_LIBRARY_PATH="$(pwd)" apps/openssl speed -evp $i
    done
}

calculate_Pn_position() {
    n=$1
    Pn=$2
    echo "scale=0; ($n - 1) * $Pn / 100 + 1" | bc -l
}

print_Pn() {
    Pns=$1
    benchmark_comparison=$2

    test_count=$(cat $benchmark_comparison | wc -l)
    benchmarks=$(cat $benchmark_comparison | sort -n -k 1)
    for i in $Pns; do 
        echo -n "P$i "
        echo "$benchmarks" | sed -n "$(calculate_Pn_position $test_count $i)p" | grep -o "^[^ ]*"
    done
}

benchmark_cmp() {
    first_benchmark=$1
    second_benchmark=$2

    cat $first_benchmark | grep "^Doing" | sed -E "s/[ \r]+$//" > b1.txt
    cat $second_benchmark | grep "^Doing" | sed -E "s/[ \r]+$//" > b2.txt
    paste b1.txt b2.txt | awk '{match($0, /(^[^:]+)/, g1); match($0, /\t+(Doing[^:]+)/, g2); if (g1[1] != g2[1]) exit -1}' \
        || { echo "Benchmark test sets are not identical"; rm b1.txt b2.txt; exit -1; } 
    cat b2.txt | sed -E "s/^[^:]+: /\/\t/" | sed -E "s/ .* / /" > b2_1.txt
    paste b1.txt b2_1.txt | awk '{match($0, /: ([0-9]+)/, g1); match($0, /([\.0-9]+)s\t\//, g2); match($0, /\/\t([0-9]+) /, g3); match($0, /([\.0-9]+)s$/, g4); printf "%f %s\n", (g3[1] / g4[1]) / (g1[1] / g2[1]), $0}'
    rm b1.txt b2.txt b2_1.txt
}

benchmark_snapshot() {
    benchmark_snapshot_result=$1
    benchmark_image=$2

    benchmark_cmp benchmark_arm64_clangcl.txt benchmark_aarch64_gcc.txt > $benchmark_snapshot_result || exit -1

    chart_payload="cht=bvg&chs=500x375&chtt=Perfromance%20ratio%20comparison&chma=30,30,30,30&chdlp=t&chco=4d89f9,c6d9fd&chbh=r,0,0&chxt=x,x,y&chxl=1:|Benchmark%20test%20%23&chxp=1,50&chds=a&chxs=2N*p&chdl=AArch64%20/%20Arm64%20Windows&chxr=0,0,247,48&chd=t:"
    chart_payload+=$(cat $benchmark_snapshot_result \
        | sort -n -r -k 1 \
        | awk '{val = $1; if (val >= 1) val -= 1; else val = -1/val + 1; printf "%f,", val}')
    chart_payload="${chart_payload%?}"

    curl -X POST -d "$chart_payload" https://chart.googleapis.com/chart > $benchmark_image
}

get_latest_benchmark_snapshot () {
    echo .github/benchmark_snapshot/$(ls .github/benchmark_snapshot | sort -r -k 1 | head -n 1)
}

verify_benchmark_regression() {
    benchmark_cmp benchmark_arm64_clangcl.txt benchmark_aarch64_gcc.txt > b1 || exit -1
    latest_benchmark_snapshot=$(get_latest_benchmark_snapshot)
    echo The latest benchmark snapshot: $latest_benchmark_snapshot
    print_Pn "25 50 75 95 99 100" $latest_benchmark_snapshot > Pn_latest
    print_Pn "25 50 75 95 99 100" b1 > Pn_current
    echo Pn latest_snapshot current percentage_change
    paste Pn_latest Pn_current | awk 'begin{max = 0} {change = $4 * 100 / $2 - 100; if (max < change) max = change; printf "%s %s %s %f\n", $1, $2, $4, change} END {if (max > 10) print "Potential benchmark regression has been detected"}' > change
    cat change
    cat change | grep -q "Potential benchmark regression has been detected" && exit 1 || echo "Benchmark regression has not been detected"
}

command=$1
shift

$command "$@"

