#!/bin/bash 

# 監視間隔を秒で指定 
readonly INTERVAL=0 
IFS=$'\n' 
readonly PROJECT_DIR="$(cd $(dirname "$0"); cd ../; pwd)" 
export no=1 

function monitor() { 
  cd "$1" 
  ((dir_index++)) 
  local _hash=$(shasum -a 256 $(ls -p | grep -v / || echo "$1") | shasum -a 256) 
  if [ ${_hash} != ${buffer[${dir_index}]:=${_hash}} ]; then 
    buffer[${dir_index}]=${_hash} 
    ((build_flag++)) 
  fi 
  for _sub_dirname in $(ls -F | grep /); do 
    monitor "${_sub_dirname}" 
  done 
  cd ../ 
} 

while true; do 
  sleep ${INTERVAL} 
  dir_index=0 build_flag=0 
  monitor "${PROJECT_DIR}/src" 
  if [ ${build_flag} -ne 0 ]; then 
    "${PROJECT_DIR}/sh/build.sh" & 
    ((no++)) 
  fi 
done 