#!/bin/bash 

set -u 
# 監視間隔を秒で指定 
readonly INTERVAL=1 
readonly PROJECT_DIR=$(cd $(dirname $0); cd ../; pwd) 
. ${PROJECT_DIR}/sh/component/functions.sh 
if [ $# -gt 1 ]; then 
  echo "src直下のディレクトリをひとつ監視します．" 
  exit 1 
fi 
export TARGET_DIRNAME=${1:-md} 
cd ${PROJECT_DIR}/src/${TARGET_DIRNAME} || exit 1 
export no=1 
export filename=0 
# ファイル数を記録 
number_of_files=$(ls -U1 | wc -l) 
buffer="A" 
initial_hash $(xor_buffer) ${buffer} 
while true; do 
  index=0 
  for filename in *; do 
    eval ${buffer}[${index}]="$(update_hash ${filename})" 
    if [ "${A[${index}]})" != "${B[${index}]})" ]; then 
      if [ ${number_of_files} -eq $(ls -U1 | wc -l) ]; then 
        ${PROJECT_DIR}/sh/build.sh & 
        no=$(( no + 1 )) 
        buffer=$(xor_buffer) 
      else 
        no=1 
        initial_hash $(xor_buffer) ${buffer} 
      fi 
      break 1 
    fi 
    index=$(( index + 1 )) 
  done 
  sleep INTERVAL 
done 
