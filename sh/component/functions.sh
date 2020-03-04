#!/bin/bash 

. ${PROJECT_DIR}/sh/component/multidimensional_arrays.sh 

readonly ORI_IFS=${IFS} 

# この関数が呼ばれたとき，二値の状態変数bufferが参照してないもう片方を返す関数 
function xor_buffer () { 
  # -eqは文字の比較条件式に使えない 
  if [ "${buffer}" = "A" ] ; then 
    buffer="B" 
  else 
    buffer="A" 
  fi 
  return 0 
} 

# ハッシュ値を更新する関数 
function update_hash () { 
  # Thanks to https://qiita.com/tamanobi/items/74b62e25506af394eae5 
  echo $(openssl sha256 -r $1 | awk '{print $1}') 
  return 0 
} 

function debug () { 
  check_state 
    local _level_debug=1
    if [ $# -eq 0 ] || [ $1 -eq 1 ]; then 
      local _argument_debug=1 
    else 
      local _argument_debug=$1 
    fi 
    if [ "${_level_debug}" -ge "${_argument_debug}" ]; then 
      if [ $# -ge 2 ]; then 
        case "$2" in 
          files_in ) 
            # echo "$(read_state)[$3] = # \"${}\"" 
            # echo "${array_state[@]}[$3] = # \"${}\"" 
            # echo "${array_state[@]}" 
          ;; 
          update ) 
            # echo "$(read_state)[$3] = \"$(roster $3)\"" 
            echo "${array_state[@]}[$3] = \"$(roster $3)\"" 
            # echo "${array_state[@]}" 
          ;; 
          watcher ) 
            echo "消されたファイル名" 
            echo "${_erased_filename[@]}" # 消されたファイルのハッシュ値を表示 
            echo "更新されたファイル名" 
            echo "${_overwrite_filename[@]}" # 上書きすべきファイル名を表示 
          ;; 
          * ) 
            echo "$2" 
          ;; 
        esac 
      else 
        echo "${array_state[@]}" 
      fi 
    fi 
  rest_state 
  return 0 
} 

# Thanks to http://doi-t.hatenablog.com/entry/2013/12/07/023638 
killtree() {
    local _pid=$1
    local _sig=${2:-TERM}
    kill -stop ${_pid} # needed to stop quickly forking parent from producing child between child killing and parent killing
    for _child in $(ps -o pid --no-headers --ppid ${_pid}); do
        killtree ${_child} ${_sig}
    done
    kill -${_sig} ${_pid}
}

function cleanup_manager () { 
  index_pid=0 
  for target in ${TARGET_DIRNAME} 
  do 
    killtree ${pid[${index_pid}]} 
    index_filename=0 
  done 
  echo "cleanup up!" 
} 

function cleanup_watcher () { 
  : 
} 