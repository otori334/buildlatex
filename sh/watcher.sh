#!/bin/bash 

# 監視間隔を秒で指定 
readonly INTERVAL=1 
IFS=$'\n' 
export PROJECT_DIR="$(cd "$(dirname "$0")"; cd ../; pwd)" 
export CURRENT_BRANCH="$(cd "${PROJECT_DIR}"; git rev-parse --abbrev-ref HEAD)" 
export BRANCH_DIR="/tmp/buildlatex_${CURRENT_BRANCH}" 
export CACHE_DIR="${BRANCH_DIR}/cache" 
export BUILD_DIR 
export relative_path 
export no=0 
trap 'echo "end watcher.sh" && rm -rf "${BUILD_DIR}" && exit' 0 1 2 3 15 

function setup() { 
  build_flag=0 
  dir_index=0 
  max_depth=0 
  depth=0 
} 

function glance() { 
  cd "$1" 
  if [ $((++depth)) -gt ${max_depth} ]; then 
    max_depth=${depth} 
  fi 
  for _sub_dirname in $(ls -p | grep /$); do 
    glance "${_sub_dirname}" 
  done 
  eval depth_${depth}+='('"$(pwd | sed -e "s:^${PROJECT_DIR}::")"')' 
  ((depth--)) 
  cd ../ 
} 

function watch() { 
  cd "$1" 
  if [ $((++depth)) -gt ${max_depth} ]; then 
    max_depth=${depth} 
  fi 
  local _build_flag=${build_flag} 
  for _sub_dirname in $(ls -Ap | grep /$); do 
    watch "${_sub_dirname}" 
  done 
  local _list_file="$(ls -Ap | grep -v /$ 2> /dev/null)" 
  local _hash="$(shasum -a 256 ${_list_file:-./} 2> /dev/null | shasum -a 256)" 
  ((dir_index++)) 
  if [ "${_hash}" != "${buffer[${dir_index}]:=${_hash}}" ]; then 
    buffer[${dir_index}]="${_hash}" 
    ((build_flag++)) 
  fi 
  if [ ${_build_flag} -ne ${build_flag} ]; then 
    eval depth_${depth}+='('"$(pwd | sed -e "s:^${PROJECT_DIR}::")"')' 
  fi 
  ((depth--)) 
  cd ../ 
} 

function build() { 
  local _build_pid=$(bash -c 'echo ${PPID}') 
  BUILD_DIR="${BRANCH_DIR}/${_build_pid}" 
  mkdir -p "${BUILD_DIR}" 
  cp -R "${CACHE_DIR}/src" "${BUILD_DIR}/" 2> /dev/null || cp -R "${PROJECT_DIR}/src" "${BUILD_DIR}/" 

  for depth in $(seq ${max_depth} -1 1 ); do 
    for relative_path in $(eval echo '"${'depth_${depth}'[*]}"'); do 
      "${PROJECT_DIR}${relative_path:-ERROR}/processing.sh" & 
    done 
    wait 
  done 
  rm -rf "${CACHE_DIR}" 
  mv "${BUILD_DIR}" "${CACHE_DIR}/" 
  echo "finish ${no}"
  exit 
} 

setup 
glance "${PROJECT_DIR}/src" 
build_flag=1 

while true; do 
  if [ ${build_flag} -ne 0 ]; then 
    build &     
    ((no++)) 
    for depth in $(seq ${max_depth} -1 1 ); do 
      unset depth_${depth} 
    done 
  fi 
  sleep ${INTERVAL} 
  setup 
  watch "${PROJECT_DIR}/src" 
done 