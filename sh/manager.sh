#!/bin/bash 

readonly ORI_IFS=${IFS} 
readonly PID=$$ 
readonly PROJECT_DIR=$(cd $(dirname $0); cd ../; pwd) 
readonly CURRENT_BRANCH=$(cd ${PROJECT_DIR}; git rev-parse --abbrev-ref HEAD) 
# 引数処理 
if [ $# -ne 0 ]; then 
  # 引数で注目するディレクトリ（TARGET_DIR）をsrc直下のディレクトリの中から選び指定 
  readonly TARGET_DIR=$@ 
else 
  # 引数がなければsrc直下すべてのディレクトリを監視 
  readonly TARGET_DIR=$(find ${PROJECT_DIR}/src/ -type d -depth 1 | sed 's!^.*/!!' | sort -f) 
fi 
# 監視間隔を秒で指定 
readonly INTERVAL=1 
# 変化検知毎にインクリメントさせる変数 
counter=0 

. ${PROJECT_DIR}/sh/multidimensional_arrays.sh 

function debug () { 
  check_state 
    local _level_debug=2
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
            echo "${erased_files0[@]}" # 消されたファイルのハッシュ値を表示 
            echo "更新されたファイル名" 
            echo "${overwrite_files2[@]}" # 上書きすべきファイル名を表示 
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

# この関数が呼ばれたとき，二値の状態変数bufferが参照してないもう片方を返す関数 
function xor_buffer () { 
  # -eqは文字の比較条件式に使えない 
  if [ "${buffer}" = "A" ] ; then 
    echo "B" 
  else 
    echo "A" 
  fi 
  return 0 
} 

# target中のファイル名一覧を格納・更新する関数 
function files_in () { 
  check_state 
    mode="file"; debug 2 
    # Thanks to https://aimstogeek.hatenablog.com/entry/2016/02/07/000318 
    # シェルスクリプトでfindした結果を配列で受け取る 
    # Thanks to https://qiita.com/catfist/items/ef5b6496f5ce7b0abcc2 
    # .DS_Store 無視 
    local _index_files_in=0 
    local _file_files_in=0 
    # Thanks to https://www.marketechlabo.com/bash-batch-best-practice/ 
    # sed 's!^.*/!!'何かわからないけど多分パスの後ろの/を削ってる・無いと動かない 
    for _file_files_in in $(find ${PROJECT_DIR}/src/${target} -type f -maxdepth 2 ! -name .DS_Store | sed 's!^.*/!!' | sort -n); do 
      eval $(read_state)[${_index_files_in}]="${_file_files_in}" 
      eval "${buffer}"_$(echo "${_file_files_in}" | tr '\,' '_' | tr '\.' '_' )="${_index_files_in}" 
      debug 3 files_in ${_index_files_in} 
      # Thanks to http://unix.oskp.net/shellscript/while_until.html 
      # Thanks to https://qiita.com/d_nishiyama85/items/a117d59a663cfcdea5e4 
      _index_files_in=$(( _index_files_in + 1 )) 
    done 
    # exit 
  rest_state 
  return 0 
} 

# ハッシュ値を更新する関数 
function update_hash () { 
  # Thanks to https://qiita.com/tamanobi/items/74b62e25506af394eae5 
  echo $(openssl sha256 -r $1 | awk '{print $1}') 
  return 0 
} 

# ハッシュ値一覧を4次元配列に格納・更新する関数 
function update () { 
  check_state 
    mode="hash"; debug 2 
    # ファイル名一覧を格納・更新 
    files_in 
    cd ${PROJECT_DIR}/src/${target} 
    local _index_update=0 
    local _file_update=0 
    for _file_update in $(roster $(edit_state $(read_state) mode file) @); do 
      # Thanks to https://qiita.com/laikuaut/items/96dd37a8a59a87ece2ea 
      # bashで文字列を変数名に展開する方法 
      eval $(read_state)[${_index_update}]=$(update_hash ${_file_update}) 
      eval _$(roster ${_index_update})="${_file_update}" 
      debug 3 update ${_index_update} 
      _index_update=$(( _index_update + 1 )) 
    done 
  rest_state 
  return 0 
} 

# ハッシュ値の初期値を取得する関数 
function initial_hash () { 
  check_state 
    buffer="B"; debug 2 
    for target in ${TARGET_DIR}; do 
      debug 2 
      update 
    done 
  rest_state 
  return 0 
} 

function watcher () { 
  check_state 
    mode="hash"; debug 2 
    # 変化した場合 
    if [ "$(roster)" != "$(roster $(edit_state $(read_state) buffer $(xor_buffer)) @)" ] ; then 
      local _PRE_IFS=${IFS}; IFS=$'\n' 
        # Thanks to https://anmino.hatenadiary.org/entry/20091020/1255988532 
        # Thanks to https://qiita.com/mtomoaki_96kg/items/ff82305f1ff4bb4c827c 
        # 増減に関わらないファイルを割り出す 
        mode="file"; debug 2 
        both_file_diff=( $({ roster $(read_state) '*'; roster $(edit_state $(read_state) buffer $(xor_buffer)) '*'; } | sort | uniq -d) ) 
        # 消されたファイル名を割り出す 
        erased_files0=( $({ echo "${both_file_diff[*]}"; roster $(edit_state $(read_state) buffer $(xor_buffer)) '*'; } | sort | uniq -u) ) 
        # もう一つの buffer のハッシュ値について操作 
        buffer="$(xor_buffer)"; mode="hash"; debug 2 
        # 消されたファイルのハッシュ値を検索 
        local _file_watcher=0 
        local _vision_watcher=0 
        for _file_watcher in ${erased_files0[@]}; do 
          _vision_watcher="${buffer}_$(echo "${_file_watcher}" | tr '\,' '_' | tr '\.' '_' )" 
          erased_files1+=( $(roster ${_vision_watcher}) ) 
          eval unset "${_vision_watcher}" 
        done 
        # 上書きすべきファイルを割り出す 
        overwrite_files0=( $({ roster $(read_state) '*'; roster $(edit_state $(read_state) buffer $(xor_buffer)) '*'; echo "${erased_files1[*]}"; } | sort | uniq -u) ) 
        # 上書きすべきファイル名を検索 
        for _file_watcher in ${overwrite_files0[@]}; do 
          overwrite_files1+=( $(eval echo '"${_'${_file_watcher}'}"') ) 
          eval unset "_${_file_watcher}" 
        done 
        
        overwrite_files2=( $( echo "${overwrite_files1[*]}" | sort | uniq -d ) ) 
        # debug 1 watcher 
        
        rm empty2.out # 変わるファイルを消す 
      IFS=${_PRE_IFS} 
    else 
      echo "ハッシュが変わらない場合" 
      : 
    fi 
    no=334
    # 渡したい状態　消去と変化同時　消去のみ　変化のみ
    # それぞれの要素の数
    
    # ${PROJECT_DIR}/sh/test.sh $no ${erased_files0[@]}& 
    # ${PROJECT_DIR}/sh/build.sh $no $nowdate $nowtime $c& 
    
    
    echo "終了"; exit 
  rest_state 
  return 0 
} 

function processing () { 
  index=0 
  until [ $index -eq 10 ]; do 
    index=$(( index + 1 )) 
    echo $index 
  done 
  exit 
  # https://linuxcommand.net/read/#read-2 
  # whileと組み合わせてファイルから行を読み込む 
  return 0 
} 


def_state buffer 
def_state target 
def_state mode 

cd ${PROJECT_DIR}/src/eq 
# 消えるファイル 
touch empty1.out 
echo "empty1" | tee empty1.out 

touch empty3.out 
echo "empty3" | tee empty3.out 

# 変わるファイル 
touch empty2.out 

initial_hash 

# 監視開始 
check_state     
  echo "ready" 
  while true; do 
    for buffer in "A" "B"; do 
      # sleep $INTERVAL 
      for target in ${TARGET_DIR}; do 
        cd ${PROJECT_DIR}/src/eq 
        rm empty1.out 
        rm empty3.out 
        echo "empty2" | tee empty2.out 
        # update では変わらないファイルが重要 
        update 
        watcher 
        exit 
      done 
      # ここでシェル呼ぶか判断 
      exit 
    done 
  done 
rest_state
exit # 監視終了 

nowdate=`date '+%Y/%m/%d'` 
nowtime=`date '+%H:%M:%S'` 
no=`expr $no + 1` 
${PROJECT_DIR}/sh/build.sh $no $nowdate $nowtime $c& 
#${PROJECT_DIR}/sh/test.sh $no $nowdate $nowtime $c& 
echo "update_hashd\nno:$no\ndate:$nowdate\ntime:$nowtime\nfile:$c\n" 
