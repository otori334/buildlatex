#!/bin/bash 

. ${PROJECT_DIR}/sh/component/multidimensional_arrays.sh 

# この関数が呼ばれたとき，二値の状態変数 buffer が参照してないもう片方を返す 
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

# ハッシュ値の配列を初期化する関数 
function initial_hash() { 
  # ファイル数をグローバル変数に記録 
  number_of_files=$(ls -U1 | wc -l) 
  # 配列を初期化 
  for _arrayname in $@ 
  do 
    eval unset ${_arrayname} 
  done 
  # 第一引数で指定された配列にハッシュ値を格納 
  local _index=0 
  for _filename in * 
  do 
    eval $1[${_index}]=$(update_hash ${_filename}) 
    _index=$(( _index + 1 )) 
  done 
} 

# これはディレクトリ構成を再起的に溶かす危険な関数．取り扱い注意 
function deploy_file() { 
  cd $1 
  for _child in $(ls -F | grep /); do 
    deploy_file ${_child} 
  done 
  # processing.sh という名前のファイルがあれば実行 
  if [ -e processing.sh ]; then 
    ./processing.sh 
    rm -f processing.sh 
  fi 
  mv * ../ 
  cd ../ 
  rm -rf $1 
} 
