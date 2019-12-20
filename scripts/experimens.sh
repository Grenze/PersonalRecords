#!/bin/bash

testAndMkdir() {
for var in "$@"
do
if [ ! -d $var ]; then 
    mkdir -p $var
fi
done
}

testAndTouch() {
if [ ! -f $1 ]; then
    touch $1
fi
}

# make sure you have db* files under ~/github, 
# and execute cmake -DCMAKE_BUILD_TYPE=Release .. && cmake --build . 
# in each ~/github/db*/build/ .
# sudo cmake install is needed for ycsb.
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

small_value_flag=true
large_value_flag=true
large_dataset_flag=true
snapshot_flag=true
cuckoo_filter_flag=true
ycsb_flag=true

for db in ${dbs[@]}
do
#echo $db
testAndMkdir $small_value$db $large_value$db $large_dataset$db $snapshot$db $ycsb$db
done

# Bytes(32GB)
data_size=34359738368
# Bytes(160GB/Value Size:16KB)
large_data_size=171798691840


db_bench="fillseq,fillrandom,overwrite,readrandom,readmissing,readseq,readreverse,seekrandom"

threads=(1 2 4 8 12 16)

small_value_size=(16 32 64 128 256 512)
large_value_size=(1024 2048 4096 8192 16384 32768 65536) # 1K 2K 4K 8K 16K 32K 64K

# while value_size >= 16K, we set write_buffer_size larger to reduce write stall.
# For leveldb, default setting : SStable file size(2M), buffer size(4M), cache size(8M)
vs_threshold=16384
max_file_size=33554432 #32M
write_buffer_size=67108864 #64M
cache_size=134217728 #128M
special_setting=" --max_file_size="${max_file_size}" --write_buffer_size="${write_buffer_size}" --cache_size="${cache_size}
#echo $special_setting

seat="/dev/shm/"

# small value size db_bench
if [ $small_value_flag ]; then
for vs in ${small_value_size[@]}
do
num=$((data_size/vs))
#echo $num
for db in ${dbs[@]}
do
output=${small_value}${db}"/"${db}"_value_size_"${vs}
#echo $output
testAndTouch $output
for th in ${threads[@]}
do
echo ${parent_path}${db}${exe_file}" --threads="${th}" --value_size="${vs}" --num="$num" --db="${seat}${db}" --benchmarks="${db_bench}
#${parent_path}${db}${exe_file}" --threads="${th}" --value_size="${vs}" --num="$num" --db="${seat}${db}" --benchmarks="${db_bench} >> output
rm -rf ${seat}${db}
#echo ${seat}${db}
done
done
done
fi

# large value size db_bench
if [ $large_value_flag ]; then
for vs in ${large_value_size[@]}
do
num=$((data_size/vs))
#echo $num
plus=""
if [ $vs -ge $vs_threshold ]; then
    plus=$special_setting
fi
for db in ${dbs[@]}
do
output=${large_value}${db}"/"${db}"_value_size_"${vs}
#echo $output
testAndTouch $output
for th in ${threads[@]}
do
echo ${parent_path}${db}${exe_file}" --threads="${th}" --value_size="${vs}" --num="$num" --db="${seat}${db}" --benchmarks="${db_bench}${plus}
#${parent_path}${db}${exe_file}" --threads="${th}" --value_size="${vs}" --num="$num" --db="${seat}${db}" --benchmarks="${db_bench}${plus} >> output
rm -rf ${seat}${db}
#echo ${seat}${db}
done
done
done
fi

# Large DataSet
if [ $large_dataset_flag ]; then
vs=16384
num=$((large_data_size/vs))
#echo $num
plus=""
if [ $vs -ge $vs_threshold ]; then
    plus=$special_setting
fi
for db in ${dbs[@]}
do
output=${large_dataset}${db}"/"${db}"_value_size_"${vs}
#echo $output
testAndTouch $output
th=1
echo ${parent_path}${db}${exe_file}" --threads="${th}" --value_size="${vs}" --num="$num" --db="${seat}${db}" --benchmarks="${db_bench}${plus}
#${parent_path}${db}${exe_file}" --threads="${th}" --value_size="${vs}" --num="$num" --db="${seat}${db}" --benchmarks="${db_bench}${plus} >> output
rm -rf ${seat}${db}
#echo ${seat}${db}
done
fi

# Snapshot
if [ $snapshot_flag ]; then
db_bench_snap="fillseq,snapshot,overwrite,overwrite,overwrite,readrandom,readmissing,readrandomsnapshot,readseq,readseqsnapshot,readreverse,readreversesnapshot,seekrandom,seekrandomsnapshot"
vs=16384
num=$((data_size/vs))
#echo $num
plus=""
if [ $vs -ge $vs_threshold ]; then
    plus=$special_setting
fi
for db in ${dbs[@]}
do
output=${snapshot}${db}"/"${db}"_value_size_"${vs}
#echo $output
testAndTouch $output
th=1
echo ${parent_path}${db}${exe_file}" --threads="${th}" --value_size="${vs}" --num="$num" --db="${seat}${db}" --benchmarks="${db_bench_snap}${plus}
#${parent_path}${db}${exe_file}" --threads="${th}" --value_size="${vs}" --num="$num" --db="${seat}${db}" --benchmarks="${db_bench_snap}${plus} >> output
rm -rf ${seat}${db}
#echo ${seat}${db}
done
fi

# Cuckoo Filter
if [ $cuckoo_filter_flag ]; then
db_bench_filter=${db_bench}" --use_cuckoo=0"
vs=16384
num=$((data_size/vs))
#echo $num
plus=""
if [ $vs -ge $vs_threshold ]; then
    plus=$special_setting
fi
db="softdb"
output=${cuckoo_filter}${db}"/"${db}"_value_size_"${vs}
#echo $output
testAndMkdir $cuckoo_filter$db
testAndTouch $output
for th in ${threads[@]}
do
echo ${parent_path}${db}${exe_file}" --threads="${th}" --value_size="${vs}" --num="$num" --db="${seat}${db}" --benchmarks="${db_bench_filter}${plus}
#${parent_path}${db}${exe_file}" --threads="${th}" --value_size="${vs}" --num="$num" --db="${seat}${db}" --benchmarks="${db_bench_filter}${plus} >> output
rm -rf ${seat}${db}
#echo ${seat}${db}
done
fi
