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
# Sudo cmake install is needed for ycsb.
dbs=("softdb" "leveldb")
parent_path="~/github/"
exe_file="/build/db_bench"
profiles="./profiles"

# directory for various benchmark
small_value=$profiles"/SmallValueSizeBenchmark/"
large_value=$profiles"/LargeValueSizeBenchmark/"
large_dataset=$profiles"/LargeDataSet/"
snapshot=$profiles"/Snapshot/"
cuckoo_filter=$profiles"/UseCuckooFilter/"
ycsb=$profiles"/YCSB/"

for db in ${dbs[@]}
do
echo $db
testAndMkdir $small_value$db $large_value$db $large_dataset$db $snapshot$db $ycsb$db
done

# Bytes(32GB)
data_size=34359738368
# Bytes(160GB/Value Size:4KB)
large_dataset=171798691840


db_bench="fillseq,fillrandom,overwrite,readrandom,readmissing,readseq,readreverse,seekrandom"

threads=(1 2 4 8 12 16)

small_value_size=(16 32 64 128 256 512)
large_value_size=(1024 2048 4096 8192 16384 32768 65536) # 1K 2K 4K 8K 16K 32K 64K

# while value_size >= 16K, we set write_buffer_size larger to reduce write stall.
# For leveldb, default setting : SStable file size(2M), buffer size(4M), cache size(8M)
max_file_size=33554432 #32M
write_buffer_size=67108864 #64M
cache_size=134217728 #128M

seat="/dev/shm/"

for vs in ${small_value_size[@]}
do
num=$((data_size/vs))
#echo $num
for db in ${dbs[@]}
do
output=${small_value}${db}"/"${db}"_value_size_"${vs}
#echo $output
for th in ${threads[@]}
do
#echo ${parent_path}${db}${exe_file}" --threads="${th}" --value_size="${vs}" --num="$num" --db="${seat}${db}" --benchmarks="${db_bench}
${parent_path}${db}${exe_file}" --threads="${th}" --value_size="${vs}" --num="$num" --db="${seat}${db}" --benchmarks="${db_bench} >> output
rm -rf ${seat}${db}
#echo ${seat}${db}
done
done
done

for vs in ${large_value_size[@]}
do
num=$((data_size/vs))
#echo $num
for db in ${dbs[@]}
do
ouput=${large_value}${db}"/"${db}"_value_size"${vs}
#echo $outpupt
for th in ${threads[@]}
do
#echo ${parent_path}${db}${exe_file}" --threads="${th}" --value_size="${vs}" --num="$num" --db="${seat}${db}" --benchmarks="${db_bench}
${parent_path}${db}${exe_file}" --threads="${th}" --value_size="${vs}" --num="$num" --db="${seat}${db}" --benchmarks="${db_bench} >> output
done
done
done



