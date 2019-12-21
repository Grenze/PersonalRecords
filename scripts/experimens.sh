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

# /home/yourname/github/db*
user_name=$1

# make sure you have db* files under ~/github, 
# and execute cmake -DCMAKE_BUILD_TYPE=Release .. && cmake --build . 
# in each ~/github/db*/build/ .
# sudo cmake install is needed for ycsb.
dbs=("leveldb" "softdb")
parent_path="/home/"${user_name}"/github/"
exe_file="/build/db_bench"
profiles="./profiles"

# directory for various benchmark
small_value=$profiles"/SmallValueSizeBenchmark/"
large_value=$profiles"/LargeValueSizeBenchmark/"
large_dataset=$profiles"/LargeDataSet/"
snapshot=$profiles"/Snapshot/"
cuckoo_filter=$profiles"/UseCuckooFilter/"
ycsb=$profiles"/YCSB/"

small_value_flag=1
large_value_flag=1
large_dataset_flag=1
snapshot_flag=1
cuckoo_filter_flag=1
ycsb_flag=1

for db in ${dbs[@]}
do
#echo $db
testAndMkdir $small_value$db $large_value$db $large_dataset$db $snapshot$db $ycsb$db
done

# 2^24
small_data_num=16777216
# Bytes(1GB)
small_data_size=1073741824
# Bytes(32GB)
data_size=34359738368
# Bytes(160GB/Value Size:16KB)
large_data_size=171798691840


db_bench="fillseq,fillrandom,overwrite,readrandom,readmissing,readseq,readreverse,seekrandom"

threads=(1 2 4 8 12 16)

small_value_size=(16 32 64 128 256 512)
large_value_size=(1024 2048 4096 8192 16384 32768 65536) # 1K 2K 4K 8K 16K 32K 64K

# while value_size >= 8K, we set write_buffer_size larger to reduce write stall.
# For leveldb, default setting : SStable file size(2M), buffer size(4M), cache size(8M)
vs_threshold=8192
max_file_size=33554432 #32M
write_buffer_size=67108864 #64M
cache_size=134217728 #128M
special_setting=" --max_file_size="${max_file_size}" --write_buffer_size="${write_buffer_size}" --cache_size="${cache_size}
#echo $special_setting

seat="/dev/shm/"

# small value size db_bench
if [ $small_value_flag -eq 1 ]; then
for vs in ${small_value_size[@]}
do
num=$small_data_num
#num=$((small_data_size/vs))
#if [ $vs -eq 16 ]; then # overflow
#num=$(($((data_size-16))/vs))
#fi
#echo $num
for db in ${dbs[@]}
do
output=${small_value}${db}"/"${db}"_value_size_"${vs}
#echo $output
testAndTouch $output
for th in ${threads[@]}
do
echo ${parent_path}${db}${exe_file}" --threads="${th}" --value_size="${vs}" --num="$num" --db="${seat}${db}" --benchmarks="${db_bench}
exe_str=${parent_path}${db}${exe_file}" --threads="${th}" --value_size="${vs}" --num="$num" --db="${seat}${db}" --benchmarks="${db_bench}
nohup $exe_str >> $output &
wait $!
rm -rf ${seat}${db}
#echo ${seat}${db}
done
done
done
fi

# large value size db_bench
if [ $large_value_flag -eq 1 ]; then
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
exe_str=${parent_path}${db}${exe_file}" --threads="${th}" --value_size="${vs}" --num="$num" --db="${seat}${db}" --benchmarks="${db_bench}${plus}
nohup $exe_str >> $output &
wait $!
rm -rf ${seat}${db}
#echo ${seat}${db}
done
done
done
fi

# Large DataSet
if [ $large_dataset_flag -eq 1 ]; then
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
exe_str=${parent_path}${db}${exe_file}" --threads="${th}" --value_size="${vs}" --num="$num" --db="${seat}${db}" --benchmarks="${db_bench}${plus}
nohup $exe_str >> $output &
wait $!
rm -rf ${seat}${db}
#echo ${seat}${db}
done
fi

# Snapshot
if [ $snapshot_flag -eq 1 ]; then
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
exe_str=${parent_path}${db}${exe_file}" --threads="${th}" --value_size="${vs}" --num="$num" --db="${seat}${db}" --benchmarks="${db_bench_snap}${plus}
nohup $exe_str >> $output &
wait $!
rm -rf ${seat}${db}
#echo ${seat}${db}
done
fi

# Cuckoo Filter
if [ $cuckoo_filter_flag -eq 1 ]; then
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
exe_str=${parent_path}${db}${exe_file}" --threads="${th}" --value_size="${vs}" --num="$num" --db="${seat}${db}" --benchmarks="${db_bench_filter}${plus}
nohup $exe_str >> $output &
wait $!
rm -rf ${seat}${db}
#echo ${seat}${db}
done
fi
