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
def_state buffer "A" 
initial_hash $(xor_buffer; read_state) $(read_state) 
while true; do 
  index=0 
  for filename in *; do 
    eval $(read_state)[${index}]="$(update_hash ${filename})" 
    if [ "$(roster $(xor_buffer; read_state) ${index})" != "$(roster ${index})" ]; then 
      if [ ${number_of_files} -eq $(ls -U1 | wc -l) ]; then 
        ${PROJECT_DIR}/sh/build.sh & 
        no=$(( no + 1 )) 
        xor_buffer 
      else 
        no=1 
        initial_hash $(xor_buffer; read_state) $(read_state) 
      fi 
      break 1 
    fi 
    index=$(( index + 1 )) 
  done 
  sleep INTERVAL 
done 
