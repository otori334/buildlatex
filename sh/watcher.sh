#!/bin/bash 

set -u 
# 監視間隔を秒で指定 
readonly INTERVAL=1 
readonly PROJECT_DIR=$(cd $(dirname $0); cd ../; pwd) 
export TARGET_DIRNAME=${1:-md} 
export no=1 

# ハッシュ値を更新する関数 
function update() { 
  # Thanks to https://qiita.com/tamanobi/items/74b62e25506af394eae5 
  echo $(openssl sha256 -r $1 | awk '{print $1}') 
} 

# 初期化する関数 
function setup() { 
  cd ${PROJECT_DIR}/src/${TARGET_DIRNAME} || exit 1 
  # ハッシュ値を入れる配列 buffer を初期化 
  unset buffer 
  local _index=0 
  for _filename in *; do 
    buffer[${_index}]=$(update ${_filename}) 
    (( _index ++ )) 
  done 
  # ファイル数を記録 
  number_of_files=${_index} 
} 

setup 

# 監視 
while true; do 
  sleep ${INTERVAL} 
  index=0 
  for filename in *; do 
    if [ ${buffer[${index}]} != $(update ${filename}) ]; then 
      if [ ${number_of_files} -ne $(ls -U1 | wc -l) ]; then 
        # ファイル数が一致しない場合は初期化 
        setup 
      else 
        # コンパイルを実行 
        ${PROJECT_DIR}/sh/build.sh & 
        buffer[${index}]=$(update ${filename}) 
        (( no ++ )) 
      fi 
      # for を抜けて監視ループの最初に戻る 
      break 1 
    fi 
    (( index ++ )) 
  done 
done 
