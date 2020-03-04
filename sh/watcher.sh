#!/bin/bash 

readonly CMDNAME=$(basename $0) 
readonly PROJECT_DIR=$(cd $(dirname $0); cd ../; pwd) 
# 引数処理 
if [ $# -le 1 ]; then 
  if [ $# = 1 ]; then 
    if [ -d ${PROJECT_DIR}/src/$1 ]; then 
      readonly TARGET_DIR=${PROJECT_DIR}/src/$1 
    else 
      echo "src直下に存在するディレクトリから監視するディレクトリを一つ指定してください" 
      exit 1 
    fi 
  else 
    readonly TARGET_DIR=${PROJECT_DIR}/src/md 
  fi 
else 
  echo "${CMDNAME}が監視できるディレクトリを一つ指定してください" 
  exit 1 
fi 
cd ${TARGET_DIR} 

# 監視間隔を秒で指定 
readonly INTERVAL=1 
# 変化検知毎にインクリメントさせる変数 
export counter=0 

. ${PROJECT_DIR}/sh/component/functions.sh 

def_state buffer "A" 
index=0 
for filename in *; do 
  eval $(read_state)[${index}]=$(update_hash ${filename}) 
  index=$(( index + 1 )) 
done 
xor_buffer 
while true; do 
  while true; do 
    sleep $INTERVAL 
    now_time=${SECONDS} 
    index=0 
    for filename in * ; do 
      eval $(read_state)[${index}]=$(update_hash ${filename}) 
      if [ "$(roster $(xor_buffer; read_state) ${index})" != "$(roster ${index})" ] ; then 
        changed_filename=${filename} 
        break 2 
      fi 
      index=$(( index + 1 )) 
    done 
    if [ $(( now_time + INTERVAL )) -gt ${SECONDS} ]; then 
      sleep $(( INTERVAL - SECONDS + now_time )) 
    fi 
  done 
  xor_buffer 
  counter=$(( counter + 1 )) 
  ${PROJECT_DIR}/sh/build.sh ${counter} ${changed_filename}& 
done 
