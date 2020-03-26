#!/bin/bash 

# 監視間隔を秒で指定 
readonly INTERVAL=1 
IFS=$'\n' 
readonly PROJECT_DIR="$(cd $(dirname $0); cd ../; pwd)" 
export TARGET_DIRNAME="${1:-md}" 
export no=1 
cd "${PROJECT_DIR}/src/${TARGET_DIRNAME}" 

while true; do 
  sleep ${INTERVAL} 
  hash=$(shasum -a 256 $(ls -p | grep -v /) | shasum -a 256) 
  if [ ${hash} != ${buffer:=${hash}} ]; then 
    "${PROJECT_DIR}"/sh/build.sh & 
    buffer=${hash} 
    (( no ++ )) 
  fi 
done 