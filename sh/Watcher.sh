#!/bin/sh 

# 状態変数を定義する関数 
# 引数は二つ 
# ローカル変数の名前が状態変数の名前と衝突しないように注意する 
def_state () { 
  local PRE_IFS=${IFS} 
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
  IFS=${PRE_IFS} 
} 

# 状態変数一覧のindexを逆引きする関数 
# reverse_state 
rev_state () { 
  eval echo '$'ARRAY_STATE_NUMBER_$1 
} 

# 状態変数の規定値を調べる関数 
# minimal_state 
min_state () { 
  echo "${ARRAY_STATE_MINIMAL[$(eval echo '$'ARRAY_STATE_NUMBER_$1)]}" 
} 

# 状態変数の影響力を調べる関数 
# influence_state 
infl_state () { 
  echo "${ARRAY_STATE_INFLUENCE[$(eval echo '$'ARRAY_STATE_NUMBER_$1)]}" 
} 

# グローバル変数である状態変数にスコープを与える関数 
check_state () { 
  # 各状態変数をarray_stateに記録する 
  local PRE_IFS=${IFS} 
    local maximal_check=() 
    local state_check=0 
    for state_check in "${ARRAY_STATE_NAME[@]}"; do 
      eval maximal_check+=( $(eval echo '"${'${state_check}'}"') ) 
    done 
  IFS=_ 
    ARRAY_STATE_MAXIMAL_HEAD="${maximal_check[*]}" 
    array_state+=( "${ARRAY_STATE_MAXIMAL_HEAD}" ) 
  IFS=${PRE_IFS} 
} 

# グローバル変数である状態変数にスコープを与える関数，check_stateと合わせて使う 
rest_state () { 
  # 各状態変数をarray_stateの内容に戻す関数 
  # Thanks to https://qiita.com/tommarute/items/0085e33ac9271fbd74e1 
  # アンダーバー区切りの末尾要素から要素を抽出 
  local PRE_IFS=${IFS}; IFS=${ORI_IFS} 
    local part_rest=( $( echo "${array_state[$(( ${#array_state[@]} - 1 ))]}" | tr -s '_' ' ') ) 
    # Thanks to https://qiita.com/b4b4r07/items/e56a8e3471fb45df2f59 
    # 配列の末尾要素を読んで状態変数を復元（破壊的操作）
    array_state=( "${array_state[@]:0:$(( ${#array_state[@]} - 1 ))}" ) 
    local index_rest=0 
    local state_rest=0 
    for state_rest in "${part_rest[@]}"; do 
      eval $(echo "${ARRAY_STATE_NAME[${index_rest}]}")="${state_rest}" 
      index_rest=$(( index_rest + 1 )) 
    done 
  IFS=${PRE_IFS} 
} 

# 記録された状態変数を読む関数 
# check_stateをさかのぼって状態変数を読むことができる 
read_state () { 
  if [ $# -eq 0 ] || [ $1 -eq 0 ]; then 
    check_state 
      echo "${ARRAY_STATE_MAXIMAL_HEAD}" 
    rest_state 
    return 
  else 
    debug 2 read_state $2 
    echo "${array_state[$(( ${#array_state[@]} - $1 ))]}" 
  fi 
} 

# 引数で指定された配列名を生成する関数 
spec_state () { 
  if [ $# -eq $ARRAY_STATE_NUMBER ]; then 
    local PRE_IFS=${IFS} 
      local maximal_spec=( "$@" ) 
    IFS=_ 
      echo "${maximal_spec[*]}" 
    IFS=${PRE_IFS} 
    return 
  else 
    : # エラーハンドリング 
  fi 
} 

# 引数で指定した部分を書き換える関数 
# 第一引数は配列名，第二引数以降は書き換えたい状態変数と書き換える内容を交互にいれる 
edit_state () { 
  if [ $# -ge 3 ]; then 
    local PRE_IFS=${IFS}; IFS=${ORI_IFS} 
      local part_edit=( $( echo "$1" | tr -s '_' ' ') ) 
      if [ ${#part_edit[@]} -ne $ARRAY_STATE_NUMBER ]; then 
        : # エラーハンドリング 
        exit 1 
      fi 
      shift 1 
      until [ "$1" = "" ]; do 
        part_edit[$(rev_state $1)]="$2" 
        shift 2 
      done 
    IFS=_ 
      echo "${part_edit[*]}" 
    IFS=${PRE_IFS} 
  else 
    : # エラーハンドリング 
    exit 1 
  fi 
} 

# 定義されるよりも前に遡る場合はデフォルト値に書き換わるようにしようかな 

# 状態変数の影響力を比べる機能を組み込みたい 
# まだ 

# 擬多次元配列を参照する関数 
# Thanks to https://aki-yam.hatenablog.com/entry/20081105/1225865004 
roster() { 
  if [ $# -eq 0 ]; then 
    eval echo '"${'$(read_state)'[@]}"' 
    return 
  fi 
  if [ $# -eq 1 ]; then 
    eval echo '"${'$(read_state)'['$1']}"' 
    return 
  fi 
  if [ $# -eq 2 ]; then 
    eval echo '"${'$1'['$2']}"' 
    return 
  fi 
  : # エラーハンドリング 
  exit 1 
} 

debug () { 
  check_state 
    local level_debug=1
    if [ $# -eq 0 ] || [ $1 -eq 1 ]; then 
      local argument_debug=1 
    else 
      local argument_debug=$1 
    fi 
    if [ "${level_debug}" -ge "${argument_debug}" ]; then 
      if [ $# -ge 2 ]; then 
        case "$2" in 
          files_in ) 
            # echo "$(read_state)[$3] = \"${file}\"" 
            # echo "${array_state[@]}[$3] = \"${file}\"" 
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
        esac 
      else 
        echo "${array_state[@]}" 
      fi 
    fi 
  rest_state 
} 


# この関数が呼ばれたとき，二値の状態変数bufferが参照してないもう片方を返す関数 
xor_buffer () { 
  # -eqは文字の比較条件式に使えない 
  if [ "${buffer}" = "A" ] ; then 
    echo "B" 
  else 
    echo "A" 
  fi 
} 

# target中のファイル名一覧を格納・更新する関数 
files_in () { 
  check_state 
    mode="file"; debug 
    # Thanks to https://aimstogeek.hatenablog.com/entry/2016/02/07/000318 
    # シェルスクリプトでfindした結果を配列で受け取る 
    # Thanks to https://qiita.com/catfist/items/ef5b6496f5ce7b0abcc2 
    # .DS_Store 無視 
    local index_files_in=0 
    local file_files_in=0 
    # Thanks to https://www.marketechlabo.com/bash-batch-best-practice/ 
    # sed 's!^.*/!!'何かわからないけど多分パスの後ろの/を削ってる・無いと動かない 
    for file_files_in in $(find ${PROJECT_DIR}/src/${target} -type f -maxdepth 2 ! -name .DS_Store | sed 's!^.*/!!' | sort -n); do 
      eval $(read_state)[${index_files_in}]="${file_files_in}" 
      # eval $(read_state)[${index_files_in}]="${file_files_in}" 
      debug 2 files_in ${index_files_in}
      # Thanks to http://unix.oskp.net/shellscript/while_until.html 
      # Thanks to https://qiita.com/d_nishiyama85/items/a117d59a663cfcdea5e4 
      index_files_in=$(( index_files_in + 1 )) 
    done 
  rest_state 
} 

# ハッシュ値を更新する関数 
update_hash () { 
  # Thanks to https://qiita.com/tamanobi/items/74b62e25506af394eae5 
  echo $(openssl sha256 -r $1 | awk '{print $1}') 
} 

# ハッシュ値一覧を4次元配列に格納・更新する関数 
update () { 
  check_state 
    mode="hash"; debug 
    # ファイル名一覧を格納・更新 
    files_in 
    cd ${PROJECT_DIR}/src/${target} 
    local index_update=0 
    local file_update=0 
    
    for file_update in $(roster $(edit_state $(read_state) mode file) @); do 
      # Thanks to https://qiita.com/laikuaut/items/96dd37a8a59a87ece2ea 
      # bashで文字列を変数名に展開する方法 
      eval $(read_state)[${index_update}]=$(update_hash ${file_update}) 
      debug 2 update ${index_update} 
      index_update=$(( index_update + 1 )) 
    done 
  rest_state 
} 

# ハッシュ値の初期値を取得する関数 
initial_hash () { 
  check_state 
    buffer="B"; debug 
    for target in ${TARGET_DIR}; do 
      debug 
      update 
    done 
  rest_state 
} 

watcher () {
  echo "$0"
  check_state 
    mode="hash"; debug 
    # return
    # echo "終了"; exit 
    
    if [ "$(roster)" != "$(roster $(edit_state $(read_state) buffer $(xor_buffer)) @)" ] ; then 
      echo "ハッシュが変わった場合" 
      array_diff_b 
    else 
      echo "ハッシュが変わらない場合" 
      : 
    fi
  rest_state 
} 

# ファイルの変更を検知する関数 
array_diff_b () { 
  check_state 
    mode="hash"; debug 
    previous_index=$(eval echo '${#'$(edit_state $(read_state) buffer $(xor_buffer))'[@]}')
    current_index=$(eval echo '${#'$(read_state)'[@]}')
    echo "${array_state[@]} P${previous_index}\n${array_state[@]} C${current_index}" # デバッグ用 
    
    echo "終了"; exit 
    array_diff_d
    
    if [ ${previous_index} -eq ${current_index} ] ; then 
      echo "ファイル数が変わらない場合" 
      # ファイルのハッシュ値を調べる
      # array_diff_c 
    else 
      if [ ${previous_index} -lt ${current_index} ] ; then 
        echo "ファイル数が増えた場合" 
        # 増えたファイルを割り出す
        # array_diff_b ${buffer} 
        # cd ${PROJECT_DIR}/src/eq ; rm empty1.out
        # 増えたファイル以外のハッシュ値を調べる
        array_diff_c
        
      else 
        echo "ファイル数が減った場合" 
        # 減ったファイルを割り出す
        # array_diff_b $(xor_buffer)
        # ファイルを記録
        
        # 減ったファイル以外のハッシュ値を調べる
        array_diff_c
        
      fi
    fi
  rest_state 
}

array_diff_c () { 
  :
}

# 配列を比較する関数
# 直前の状態変数を記録したい
array_diff_d () { 
  check_state 
    mode="uniq"; debug 
    local PRE_IFS=${IFS} 
    IFS=$'\n' 
    
    # echo "終了"; exit 
    
    # Thanks to https://anmino.hatenadiary.org/entry/20091020/1255988532 
    # Thanks to https://qiita.com/mtomoaki_96kg/items/ff82305f1ff4bb4c827c
    both=( `{ echo "$(roster $(read_state 1) \*)"; echo "$(roster $(edit_state $(read_state 1) buffer $(xor_buffer)) \*)"; } | sort | uniq -d` ) 
    # previous_uniq=( $({ echo "${both[*]}"; echo "$(roster $(edit_state $(read_state) buffer $(xor_buffer)) \*)"; } | sort | uniq -u) ) 
    eval $(edit_state $(read_state) buffer $(xor_buffer))="( $({ echo "${both[*]}"; echo "$(roster $(edit_state $(read_state 1) buffer $(xor_buffer)) \* )"; } | sort | uniq -u)) "
    # current_uniq=( $({ echo "${both[*]}"; echo "$(roster $(read_state) \*)"; } | sort | uniq -u) ) 
    eval $(read_state)="( $({ echo "${both[*]}"; echo "$(roster $(read_state 1) \*)"; } | sort | uniq -u) ) "
    # echo "both\n${both[*]}"
    echo "previous\n$(roster $(edit_state $(read_state) buffer $(xor_buffer)) \*)\ncurrent\n$(roster \*)" # デバッグ用
    # echo "$(xor_buffer)_uniq\n${B_uniq[*]}\n$(read_state)\n${A_uniq[*]}" # デバッグ用
    
    exit
    # eval $(xor_buffer)_uniq= 
    # eval ${buffer}_uniq="${file}" 
    # eval $(read_state)[index]="$file" 
    IFS=${PRE_IFS} 
  rest_state; debug 
}



processing () {  
  index=0
  until [ $index -eq 10 ]; do
    index=$(( index + 1 ))  
    echo $index
  done
  exit
  # https://linuxcommand.net/read/#read-2
  # whileと組み合わせてファイルから行を読み込む
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

# cd ${PROJECT_DIR}/src/eq 
# touch empty1.out 
cd ${PROJECT_DIR}/src/eq 
touch empty1.out 
initial_hash 
# rm empty1.out 

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
            
            update 
            watcher 
            exit 
            # array_diff_b 
          done 
          # roster 
          # echo "" 
          exit 
        done 
      done 
      exit 
    done 
  done 
rest_state
exit # 監視終了 

#eval  ${PROJECT_DIR}/sh/build.sh　aaaaaaaa 
nowdate=`date '+%Y/%m/%d'` 
nowtime=`date '+%H:%M:%S'` 
no=`expr $no + 1` 
${PROJECT_DIR}/sh/build.sh $no $nowdate $nowtime $c& 
#${PROJECT_DIR}/sh/test.sh $no $nowdate $nowtime $c& 
echo "update_hashd\nno:$no\ndate:$nowdate\ntime:$nowtime\nfile:$c\n" 
