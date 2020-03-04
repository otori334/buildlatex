#!/bin/bash 

readonly CMDNAME=$(basename $0) 
readonly PROJECT_DIR=$(cd $(dirname $0); cd ../; pwd) 
. ${PROJECT_DIR}/sh/component/functions.sh 
usage () {
  : 
  echo "引数がない場合，mdのみ監視します．"
  
} 
# 引数処理 
if [ $# -ne 0 ]; then 
  # 引数で注目するディレクトリ（TARGET_DIRNAME）をsrc直下のディレクトリの中から選び指定 
  readonly TARGET_DIRNAME=$@ 
else 
  readonly TARGET_DIRNAME="md" 
  # 引数がなければsrc直下すべてのディレクトリを監視 
  # readonly TARGET_DIRNAME=$(find ${PROJECT_DIR}/src/ -type d -depth 1 | sed 's!^.*/!!' | sort -f) 
fi 
# 監視間隔を秒で指定 
readonly INTERVAL=3 
def_state buffer "A" 
def_state target 
# Thanks to http://doi-t.hatenablog.com/entry/2013/12/07/023638 
# Thanks to https://kiririmode.hatenablog.jp/entry/20160730/1469867810 
trap cleanup_manager EXIT 
index_pid=0 
for target in ${TARGET_DIRNAME} 
do 
  ${PROJECT_DIR}/sh/watcher.sh ${target} & 
  eval pid[${index_pid}]=$! 
  cd ${PROJECT_DIR}/src/${target} 
  index_filename=0 
  for filename in * 
  do 
    eval $(read_state)[${index_filename}]=${filename} 
    index_filename=$(( index_filename + 1 )) 
  done 
  index_pid=$(( index_pid + 1 )) 
done 
xor_buffer 
while true 
do 
  now_time=${SECONDS} 
  index_pid=0 
  for target in ${TARGET_DIRNAME} 
  do 
    cd ${PROJECT_DIR}/src/${target} 
    index_filename=0 
    for filename in * 
    do 
      eval $(read_state)[${index_filename}]=${filename} 
      index_filename=$(( index_filename + 1 )) 
    done 
    if [ "$(roster $(xor_buffer; read_state) @)" != "$(roster @)" ] ; then 
      kill -USR1 ${pid[${index_pid}]} 
    fi 
    index_pid=$(( index_pid + 1 )) 
  done 
  xor_buffer 
  if [ $(( now_time + INTERVAL )) -gt ${SECONDS} ]; then 
    sleep $(( now_time + INTERVAL - SECONDS )) 
  fi 
done 
