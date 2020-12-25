#!/bin/sh
nvidia-smi -L
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/cuda-11.1/compat:/usr/lib/x86_64-linux-gnu:/usr/local/cuda-11.1/targets/x86_64-linux/lib:/usr/local/cuda-11.1/targets/x86_64-linux/lib:/usr/local/cuda-10.1/targets/x86_64-linux/lib:/usr/local/cuda-10.1/lib64
cd /data/Swift4TFBenchmarks/models/MNIST
./benchmark.sh -p params.json#!/bin/sh
