#!/bin/bash

savename=$(hostname)-$(date "+%0d-%0m-%Y_%H-%M-%S")

if [[ "$#" -eq 0 ]] ; then

  cd /results

  # Download parameters and references, if they are not present
  if [ ! -e parameters.yml ] ; then 
    curl -OL https://raw.githubusercontent.com/AaltoScienceIT/docker-fgci-benchmark/master/benchmarks/parameters.yml
  fi
  if [ ! -e reference.json ] ; then 
    curl -OL https://raw.githubusercontent.com/AaltoScienceIT/docker-fgci-benchmark/master/benchmarks/reference.json 
  fi

  # Run device diagnostics
  hardinfo -r 1> ${savename}-hardinfo.txt 2> /dev/null

  cat /proc/cpuinfo > ${savename}-cpuinfo.txt

  pytest /benchmarks/benchmarks.py --benchmark-storage=/results \
    --benchmark-save=$savename \
    --benchmark-histogram=/results/histograms/$savename \
    --benchmark-compare=/results/reference.json \
    --benchmark-min-rounds=1 \
    --benchmark-disable-gc
fi

exec "$@"
