#!/bin/bash 

. ${PROJECT_DIR}/sh/component/multidimensional_arrays.sh 

# この関数が呼ばれたとき，二値の状態変数bufferが参照してないもう片方を返す関数 
function xor_buffer() { 
  # -eqは文字の比較条件式に使えない 
  if [ "${buffer}" = "A" ] ; then 
    buffer="B" 
  else 
    buffer="A" 
  fi 
  return 0 
} 

# ハッシュ値を更新する関数 
function update_hash() { 
  if [ ! -e $1 ]; then 
    return 1 
  fi 
  # Thanks to https://qiita.com/tamanobi/items/74b62e25506af394eae5 
  echo $(openssl sha256 -r $1 | awk '{print $1}') 
  return 0 
} 

# 配列を初期化する関数 
function initial_hash() { 
  # ファイル数をグローバル変数に記録 
  number_of_files=$(ls -U1 | wc -l) 
  # 配列を初期化 
  local _arrayname=0 
  for _arrayname in $@ 
  do 
    eval unset ${_arrayname} 
  done 
  # 第一引数で指定された配列にハッシュ値を格納 
  local _index=0 
  local _filename=0 
  for _filename in * 
  do 
    eval $1[${_index}]=$(update_hash ${_filename}) 
    _index=$(( _index + 1 )) 
  done 
} 

# Thanks to http://doi-t.hatenablog.com/entry/2013/12/07/023638 
function killtree() { 
    local _pid=$1 
    local _sig=${2:-TERM} 
    kill -stop ${_pid} 
    # needed to stop quickly forking parent from producing child between child killing and parent killing 
    for _child in $(ps -h -o pid -p ${_pid}); do 
        killtree ${_child} ${_sig} 
    done 
    kill -${_sig} ${_pid} 
} 

function deploy_file() { 
  cd $1 
  for _child in $(ls -F | grep /); do 
    deploy_file ${_child} 
  done 
  if [ -e processing.sh ]; then 
    ./processing.sh 
    rm -f processing.sh 
  fi 
  mv * ../ 
  cd ../ 
  rm -rf $1 
} 

function cleanup_manager() { 
  index_pid=0 
  for target in ${TARGET_DIRNAME} 
  do 
    killtree ${pid[${index_pid}]} 
    index_filename=0 
  done 
  echo "cleanup up!" 
} 

function cleanup_watcher() { 
  : 
} 