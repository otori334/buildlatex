#!/bin/bash 

# 監視間隔を秒で指定 
readonly INTERVAL=1 
readonly PROJECT_DIR="$(cd $(dirname $0); cd ../; pwd)" 
export TARGET_DIRNAME="${1:-md}" 
cd "${PROJECT_DIR}/src/${TARGET_DIRNAME}" 
export no=1 
IFS=$'\n' 

while true; do 
  sleep ${INTERVAL} 
  hash="$(openssl sha256 -r $(ls -p | grep -v /))" 
  if [ "${hash}" != "${buffer:=${hash}}" ]; then 
    "${PROJECT_DIR}"/sh/build.sh & 
    buffer="${hash}" 
    (( no ++ )) 
  fi 
done 