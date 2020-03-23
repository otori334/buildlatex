#!/bin/bash 

set -u 
# 監視間隔を秒で指定 
readonly INTERVAL=1 
readonly PROJECT_DIR=$(cd $(dirname $0); cd ../; pwd) 
export TARGET_DIRNAME=${1:-md} 
export no=1 
cd ${PROJECT_DIR}/src/${TARGET_DIRNAME} || exit 1 

buffer="$(openssl sha256 -r *)" 

function aaa() { 
  local _hash="$(openssl sha256 -r *)" 
  if [ "${buffer}" != "${_hash}" ]; then 
    ${PROJECT_DIR}/sh/build.sh & 
    buffer=${_hash} 
    (( no ++ )) 
  fi 
} 

# 監視 
while true; do 
  sleep ${INTERVAL} 
  aaa 
done 
