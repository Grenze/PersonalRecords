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
    return 1
else
    return 0
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
value_size_results=$profiles"/ValueSizeBenchmark/"
large_dataset=$profiles"/LargeDataSet/"
snapshot=$profiles"/Snapshot/"
cuckoo_filter=$profiles"/UseCuckooFilter/"
ycsb=$profiles"/YCSB/"

# whether do it or not
value_size_flag=1
large_dataset_flag=1
snapshot_flag=1
cuckoo_filter_flag=1
ycsb_flag=1

# mkdirs
for db in ${dbs[@]}
do
#echo $db
testAndMkdir $value_size_results$db $large_dataset$db $snapshot$db $ycsb$db
done

# Bytes(16GB)
data_size=17179869184
# Bytes(160GB/Value Size:16KB)
large_data_size=171798691840

db_bench="fillrandom,overwrite,readrandom,readmissing,readseq"

#threads=(1 2 4 8 16)
threads=( 1 )

#value_size=(4096 16384 65536 262144)
value_size=(1024 4096 16384 65536 262144) # 1K 4K 16K 64K 256K

# while value_size >= 8K, we set write_buffer_size larger to reduce write stall.
# For leveldb, default setting : SStable file size(2M), buffer size(4M), cache size(8M)
#vs_threshold=8192
vs_threshold=1024
#max_file_size=2097152 #2M
max_file_size=33554432 #32M
write_buffer_size=67108864 #64M
cache_size=134217728 #128M
special_setting=" --max_file_size="${max_file_size}" --write_buffer_size="${write_buffer_size}" --cache_size="${cache_size}
#echo $special_setting

seat="/dev/shm/"


# Value Size db_bench
if [ $value_size_flag -eq 1 ]; then
echo "Value Size Benchmark"
for vs in ${value_size[@]}
do
num=$((data_size/vs))
#echo $num
plus=""
if [ $vs -ge $vs_threshold ]; then
    plus=$special_setting
fi
for db in ${dbs[@]}
do
output=${value_size_results}${db}"/"${db}"_value_size_"${vs}
#echo $output
testAndTouch $output
if [ $? -eq 1 ]; then
for th in ${threads[@]}
do
echo ${parent_path}${db}${exe_file}" --threads="${th}" --value_size="${vs}" --num="$num" --db="${seat}${db}" --benchmarks="${db_bench}${plus}
exe_str=${parent_path}${db}${exe_file}" --threads="${th}" --value_size="${vs}" --num="$num" --db="${seat}${db}" --benchmarks="${db_bench}${plus}
nohup $exe_str >> $output &
wait $!
rm -rf ${seat}${db}
#echo ${seat}${db}
done
fi
done
done
fi

# Large DataSet
if [ $large_dataset_flag -eq 1 ]; then
echo "Large DataSet Benchmark"
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
if [ $? -eq 1 ]; then
th=1
echo ${parent_path}${db}${exe_file}" --threads="${th}" --value_size="${vs}" --num="$num" --db="${seat}${db}" --benchmarks="${db_bench}${plus}
exe_str=${parent_path}${db}${exe_file}" --threads="${th}" --value_size="${vs}" --num="$num" --db="${seat}${db}" --benchmarks="${db_bench}${plus}
nohup $exe_str >> $output &
wait $!
rm -rf ${seat}${db}
#echo ${seat}${db}
fi
done
fi

# Snapshot
if [ $snapshot_flag -eq 1 ]; then
echo "Snapshot Benchmark"
db_bench_snap="fillseq,snapshot,overwrite,overwrite,overwrite,readrandom,readmissing,readrandomsnapshot,readseq,readseqsnapshot"
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
if [ $? -eq 1 ]; then
th=1
echo ${parent_path}${db}${exe_file}" --threads="${th}" --value_size="${vs}" --num="$num" --db="${seat}${db}" --benchmarks="${db_bench_snap}${plus}
exe_str=${parent_path}${db}${exe_file}" --threads="${th}" --value_size="${vs}" --num="$num" --db="${seat}${db}" --benchmarks="${db_bench_snap}${plus}
nohup $exe_str >> $output &
wait $!
rm -rf ${seat}${db}
#echo ${seat}${db}
fi
done
fi

# Cuckoo Filter
if [ $cuckoo_filter_flag -eq 1 ]; then
echo "Cuckoo Filter Benchmark"
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
if [ $? -eq 1 ]; then
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
fi
