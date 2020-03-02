#!/bin/bash 

# 状態変数を定義する関数 
function def_state () { 
  # 引数は二つでもいい 
  local _PRE_IFS=${IFS} 
    if [ $# -eq 1 ]; then 
      eval $1="$1" 
    else 
      if [ $# -eq 2 ]; then 
        eval $1="$2" 
      fi 
    fi 
    # ARRAY_STATE_NAMEは状態変数の名前を格納する配列 
    ARRAY_STATE_NAME+=( $1 ) 
    # ARRAY_STATE_NUMBERはこれまでに定義された状態変数の数を格納する変数 
    ARRAY_STATE_NUMBER=${#ARRAY_STATE_NAME[@]} 
    if [ ${ARRAY_STATE_NUMBER} -eq 1 ]; then 
      # 状態変数を記録する配列 
      array_state=() 
    fi 
    # ARRAY_STATE_MINIMALは状態変数の規定値を格納する配列 
    # min_stateで参照する 
    ARRAY_STATE_MINIMAL+=( $2 ) 
    # ARRAY_STATE_INFLUENCEは状態変数の影響力を格納する配列 
    # infl_stateで参照する 
    ARRAY_STATE_INFLUENCE+=( $(( 10 - ${#ARRAY_STATE_NAME[@]} )) ) 
    # ARRAY_STATE_NUMBER_$1は状態変数のindexを格納する変数（連想配列みたいに使う）
    # rev_stateで使う 
    eval ARRAY_STATE_NUMBER_$1=$(( ${#ARRAY_STATE_NAME[@]} - 1 )) 
    # Thanks to https://qiita.com/mtomoaki_96Influencekg/items/ff82305f1ff4bb4c827c 
  IFS=_ 
    ARRAY_STATE_MINIMAL_HEAD="${ARRAY_STATE_MINIMAL[*]}" 
  IFS=${_PRE_IFS} 
  return 0 
} 

# 状態変数一覧のindexを逆引きする関数 
# reverse_state 
function rev_state () { 
  eval echo '$'ARRAY_STATE_NUMBER_$1 
  return 0 
} 

# 状態変数の規定値を調べる関数 
# minimal_state 
function min_state () { 
  echo "${ARRAY_STATE_MINIMAL[$(eval echo '$'ARRAY_STATE_NUMBER_$1)]}" 
  return 0 
} 

# 状態変数の影響力を調べる関数 
# influence_state 
function infl_state () { 
  echo "${ARRAY_STATE_INFLUENCE[$(eval echo '$'ARRAY_STATE_NUMBER_$1)]}" 
  return 0 
} 

# グローバル変数である状態変数にスコープを与える関数 
function check_state () { 
  # 各状態変数をarray_stateに記録する 
  local _PRE_IFS=${IFS} 
    local _maximal_check=() 
    local _state_check=0 
    for _state_check in "${ARRAY_STATE_NAME[@]}"; do 
      eval _maximal_check+=( $(eval echo '"${'${_state_check}'}"') ) 
    done 
  IFS=_ 
    ARRAY_STATE_MAXIMAL_HEAD="${_maximal_check[*]}" 
    array_state+=( "${ARRAY_STATE_MAXIMAL_HEAD}" ) 
  IFS=${_PRE_IFS} 
  return 0 
} 

# グローバル変数である状態変数にスコープを与える関数，check_stateと合わせて使う 
function rest_state () { 
  # 各状態変数をarray_stateの内容に戻す関数 
  # Thanks to https://qiita.com/tommarute/items/0085e33ac9271fbd74e1 
  # アンダーバー区切りの末尾要素から要素を抽出 
  local _PRE_IFS=${IFS}; IFS=${ORI_IFS} 
    local _part_rest=( $( echo "${array_state[$(( ${#array_state[@]} - 1 ))]}" | tr -s '_' ' ') ) 
    # Thanks to https://qiita.com/b4b4r07/items/e56a8e3471fb45df2f59 
    # 配列の末尾要素を読んで状態変数を復元（破壊的操作）
    array_state=( "${array_state[@]:0:$(( ${#array_state[@]} - 1 ))}" ) 
    local _index_rest=0 
    local _state_rest=0 
    for _state_rest in "${_part_rest[@]}"; do 
      eval $(echo "${ARRAY_STATE_NAME[${_index_rest}]}")="${_state_rest}" 
      _index_rest=$(( _index_rest + 1 )) 
    done 
  IFS=${_PRE_IFS} 
  return 0 
} 

# 記録された状態変数を読む関数 
# check_stateをさかのぼって状態変数を読むことができる 
function read_state () { 
  if [ $# -eq 0 ] || [ $1 -eq 0 ]; then 
    check_state 
      echo "${ARRAY_STATE_MAXIMAL_HEAD}" 
    rest_state 
    return 
  else 
    debug 3 read_state $2 
    echo "${array_state[$(( ${#array_state[@]} - $1 ))]}" 
  fi 
  return 0 
} 

# 引数で指定された配列名を生成する関数 
# 状態変数の序列を変えるとバグるため非推奨 
function spec_state () { 
  if [ $# -eq $ARRAY_STATE_NUMBER ]; then 
    local _PRE_IFS=${IFS} 
      local _maximal_spec=( "$@" ) 
    IFS=_ 
      echo "${_maximal_spec[*]}" 
    IFS=${_PRE_IFS} 
    return 
  else 
    : # エラーハンドリング 
    return 1 
  fi 
  return 0 
} 

# 引数で指定した部分を書き換える関数 
# 第一引数は配列名，第二引数以降は書き換えたい状態変数と書き換える内容を交互にいれる 
function edit_state () { 
  if [ $# -ge 3 ]; then 
    local _PRE_IFS=${IFS}; IFS=${ORI_IFS} 
      local _part_edit=( $( echo "$1" | tr -s '_' ' ') ) 
      if [ ${#_part_edit[@]} -ne $ARRAY_STATE_NUMBER ]; then 
        : # エラーハンドリング 
        exit 1 
      fi 
      shift 1 
      until [ "$1" = "" ]; do 
        _part_edit[$(rev_state $1)]="$2" 
        shift 2 
      done 
    IFS=_ 
      echo "${_part_edit[*]}" 
    IFS=${_PRE_IFS} 
  else 
    : # エラーハンドリング 
    exit 1 
  fi 
  return 0 
} 

# 定義されるよりも前に遡る場合はデフォルト値に書き換わるようにしようかな 

# 状態変数の影響力を比べる機能を組み込みたい 
# まだ 

# 擬多次元配列を参照する関数 
# Thanks to https://aki-yam.hatenablog.com/entry/20081105/1225865004 
function roster() { 
  if [ $# -eq 0 ]; then 
    eval echo '"${'$(read_state)'[@]}"' 
    return 0 
  fi 
  if [ $# -eq 1 ]; then 
    eval echo '"${'$(read_state)'['$1']}"' 
    return 0 
  fi 
  if [ $# -eq 2 ]; then 
    eval echo '"${'$1'['$2']}"' 
    return 0 
  fi 
  : # エラーハンドリング 
  exit 1 
} 

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
          read_state ) 
            if [ "$3" = "debug" ]; then 
              : 
            fi 
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
        debug 1 watcher 

        rm empty2.out # 変わるファイルを消す 
      IFS=${_PRE_IFS} 
    else 
      echo "ハッシュが変わらない場合" 
      : 
    fi 
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

# 区切り文字の設定を保存 
# Thanks to http://capm-network.com/?tag=シェルスクリプト-スペースが含まれる文字列を扱う 
readonly ORI_IFS=${IFS} 
## 実行スクリプトの保管 
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
# 監視間隔，秒で指定 
readonly interval=1 
# 変化検後にインクリメントさせる変数 
counter=0 

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
  while true; do 
    while true; do 
      while true; do 
        for buffer in "A" "B"; do 
          # sleep $interval 
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
          exit 
        done 
      done 
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
