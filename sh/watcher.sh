#!/bin/bash 

set -u 
# 監視間隔を秒で指定 
readonly INTERVAL=1 
readonly PROJECT_DIR=$(cd $(dirname $0); cd ../; pwd) 
export TARGET_DIRNAME=${1:-md} 
export no=1 
cd ${PROJECT_DIR} 

function aaa() { 
  cd ${PROJECT_DIR}/src/${TARGET_DIRNAME} 
  local _hash="$(openssl sha256 -r $(ls -p | grep -v /))" 
  if [ "${_hash}" != "${buffer:=${_hash}}" ]; then 
    # ${PROJECT_DIR}/sh/build.sh & 
    buffer=${_hash} 
    (( no ++ )) 
  fi 
} 

function test() { 
  cd $1 
  local _hash="$(openssl sha256 -r $(ls -p | grep -v /))" 
  FLAG=0 
  for _sub_dirname in $(ls -p | grep /); do 
    test ${_sub_dirname} 
  done 


  if [ ${FLAG} -ne 0 -o "${_hash}" != "${buffer:=${_hash}}" ]; then 
    # ${PROJECT_DIR}/sh/build.sh & 
    echo "aaaaaaaaaaa${FLAG}_${no}"
    buffer=${_hash} 
    (( FLAG ++ )) 
    (( no ++ )) 
    
  fi 
} 

# 監視 
while true; do 
  sleep ${INTERVAL} 
  # aaa 
  test ${PROJECT_DIR}/src/${TARGET_DIRNAME} 
  # test src
done 
