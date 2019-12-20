#!/bin/bash

testAndMkdir() {
for var in "$@"
do
if [ ! -d $var ]; then 
    mkdir -p $var
fi
done
} 

# make sure you have db* files under ~/github, 
# and execute cmake -DCMAKE_BUILD_TYPE=Release .. && cmake --build . 
# in each ~/github/db*/build/ .
# Sudo cmake install is neede for ycsb.
db1='softdb'
db2='leveldb'

profiles="./profiles"

#testAndMkdir $profiles

# directory for various benchmark
small_value=$profiles"/SmallValueSizeBenchmark/"
large_value=$profiles"/LargeValueSizeBenchmark/"
large_dataset=$profiles"/LargeDataSet/"
snapshot=$profiles"/Snapshot/"
cuckoo_filter=$profiles"/UseCuckooFilter/"
ycsb=$profiles"/YCSB/"

for db in $db1 $db2
do
testAndMkdir $small_value$db $large_value$db $large_dataset$db $snapshot$db $ycsb$db
done

exe1="~/github/"$db1"/build/db_bench"
exe2="~/github/"$db2"/build/db_bench"

# Bytes(32GB)
data_size=34359738368

db_bench="fillseq,fillrandom,overwrite,readrandom,readmissing,readseq,readreverse,seekrandom"

threads=(1 2 4 8 12 16)

small_value_size=(16 32 64 128 256 512)
large_value_size=(1024 2048 4096 8192 16384 32768 65536)
# 1K 2K 4K 8K 16K 32K 64K








