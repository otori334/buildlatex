#!/bin/bash 

readonly ORI_IFS=${IFS} 
readonly PID=$$ 
readonly PROJECT_DIR=$(cd $(dirname $0); cd ../; pwd) 
readonly CURRENT_BRANCH=$(cd ${PROJECT_DIR}; git rev-parse --abbrev-ref HEAD) 
# 引数処理 
if [ $# -ne 0 ]; then 
  # 引数で注目するディレクトリ（TARGET_DIRNAME）をsrc直下のディレクトリの中から選び指定 
  readonly TARGET_DIRNAME=$@ 
else 
  # 引数がなければsrc直下すべてのディレクトリを監視 
  readonly TARGET_DIRNAME=$(find ${PROJECT_DIR}/src/ -type d -depth 1 | sed 's!^.*/!!' | sort -f) 
fi 
# 監視間隔を秒で指定 
readonly INTERVAL=1 
# 変化検知毎にインクリメントさせる変数 
export counter=0 
# build.sh に渡す引数を一時的に格納する配列
report_arguments=() 

. ${PROJECT_DIR}/sh/multidimensional_arrays.sh 

def_state buffer 
def_state target 
def_state mode 

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
    
    if [ ${counter} -eq 0 ] ; then 
      local _vision_update=( $(roster $(mode="file"; read_state) @) )
    else 
      local _PRE_IFS=${IFS}; IFS=$'\n' 
        # 既にファイル名とハッシュ値が結びついている要素はハッシュ値を新しく計算しない 
        # ハッシュ値が変化していなかったファイル名の重複を取り除き格納 
        # local _vision_update=( $({ echo "${unchanged_files1[*]}"; roster $(edit_state $(read_state) mode file) '*'; } | sort | uniq -u ) ) 
        
        # eval echo '"${'${target}'_'${_filename_watcher}'}"'
        
        # eval ${target}_unchanged_files1+=( $(eval echo '"${_'${_filename_watcher}'}"') ) 
        
      IFS=${_PRE_IFS} 
    fi 
    cd ${PROJECT_DIR}/src/${target} 
    local _index_update=0 
    local _file_update=0 
    for _file_update in $(roster $(mode="file"; read_state) @); do 
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
    for target in ${TARGET_DIRNAME}; do 
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
    if [ "$(roster)" != "$(roster $(xor_buffer; read_state) @)" ] ; then 
      local _PRE_IFS=${IFS}; IFS=$'\n' 
        # Thanks to https://anmino.hatenadiary.org/entry/20091020/1255988532 
        # Thanks to https://qiita.com/mtomoaki_96kg/items/ff82305f1ff4bb4c827c 
        mode="file"; debug 2 
        # 増減に関わらないファイル（ _raw_filename ）を割り出す 
        local _raw_filename=( $({ 
          roster $(read_state) '*'; 
          roster $(xor_buffer; read_state) '*'; 
        } | sort | uniq -d) ) 
        # 追加されたファイル名（ _added_filename ）を割り出す 
        local _added_filename=( $({ 
          echo "${_raw_filename[*]}"; 
          roster '*'; 
        } | sort | uniq -u) ) 
        # 消されたファイル名（ _erased_filename ）を割り出す 
        local _erased_filename=( $({ 
          echo "${_raw_filename[*]}"; 
          roster $(xor_buffer; read_state) '*'; 
        } | sort | uniq -u) ) 
        mode="hash"; debug 2 
        # ハッシュ値が変化していないファイルのハッシュ値（ _unchanged_filehash ）を割り出す 
        local _unchanged_filehash=( $({ 
          roster $(xor_buffer; read_state) '*'; 
          roster '*'; 
        } | sort | uniq -d) ) 
        # ハッシュ値が変化していないファイル名を検索し配列（ buffer_${target}_steady ）に格納 
        # 次の update で計算量が減る 
        local _steady_watcher=$(buffer=buffer; mode=steady; read_state) 
        local _filename_watcher=0 
        local _index_watcher=0 
        for _filename_watcher in ${_unchanged_filehash[@]}; do 
          eval $(echo ${_steady_watcher})[${_index_watcher}]=$(eval echo '"${_'${_filename_watcher}'}"') 
          _index_watcher=$(( _index_watcher + 1 )) 
        done 
        # もう片方の buffer を操作 
        xor_buffer 
        # 消されたファイルのハッシュ値（ _erased_filehash ）を検索 
        local _vision_watcher=0 
        local _erased_filehash=() 
        _index_watcher=0 
        for _filename_watcher in ${_erased_filename[@]}; do 
          _vision_watcher="${buffer}_$(echo "${_filename_watcher}" | tr '\,' '_' | tr '\.' '_' )" 
          _erased_filehash+=( $(roster ${_vision_watcher}) ) 
          eval unset "${_vision_watcher}" 
        done 
        # 上書きすべきファイルのハッシュ値（ _overwrite_filehash ）を割り出す 
        local _overwrite_filehash=( $({ 
          echo "${_erased_filehash[*]}"; 
          roster $(xor_buffer; read_state) '*'; 
          roster '*'; 
        } | sort | uniq -u) ) 
        # 上書きすべきファイル名（ _overwrite_filename_prov ）を検索し格納 
        local _overwrite_filename_prov=() 
        for _filename_watcher in ${_overwrite_filehash[@]}; do 
          _overwrite_filename_prov+=( $(eval echo '"${_'${_filename_watcher}'}"') ) 
          eval unset "_${_filename_watcher}" 
        done 
        # 上書きすべきファイル名（ _overwrite_filename_prov ）の重複を取り除き配列（ _overwrite_filename ）に格納
        _overwrite_filename=( $( echo "${_overwrite_filename_prov[*]}" | sort | uniq -d ) ) 
        
        
        # ハッシュ値が変化したファイル名（ _changed_filename ）を割り出す 
        local _changed_filename=( $({ 
          echo "${_added_filename[*]}"; 
          echo "${_overwrite_filename[*]}" 
        } | sort | uniq -u) ) 
        
        echo "_erased_filename"
        echo "${#_erased_filename[@]}"
        echo "${_erased_filename[@]}"
        echo "_overwrite_filename"
        echo "${#_overwrite_filename[@]}"
        echo "${_overwrite_filename[@]}"
        echo "_added_filename"
        echo "${#_added_filename[@]}"
        echo "${_added_filename[@]}"
        echo "_changed_filename"
        echo "${#_changed_filename[@]}"
        echo "${_changed_filename[@]}"
        
        
        debug 1 watcher 
        
        rm empty4.out; rm empty2.out; echo "終了";debug 2; exit # 変わるファイルを消す 
        
        
        ${PROJECT_DIR}/sh/build.sh& 
        # フラグのために変更されたファイルを求める
        
        report_arguments+=( "${target}") 
        
        
      IFS=${_PRE_IFS} 
    else 
      echo "ハッシュが変わらない場合" 
      : 
    fi 
    no=334
    
    # update では変わらないファイルの名前が重要 
    
    # 渡したい状態　消去と変化同時　消去のみ　変化のみ 
    # それぞれの要素の数 
    
    # ${PROJECT_DIR}/sh/test.sh $no ${_erased_filename[@]}& 
    # ${PROJECT_DIR}/sh/build.sh $no $nowdate $nowtime $c& 
    
    # echo "${unchanged_files1[@]}" 
    rm empty4.out; rm empty2.out; echo "終了";debug 2; exit # 変わるファイルを消す 

  rest_state 
  return 0 
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

cd ${PROJECT_DIR}/src/eq 
# 消えるファイル 
touch empty1.out 
echo "empty1" | tee empty1.out 

touch empty3.out 
echo "empty3" | tee empty3.out 

# 変わるファイル 
touch empty2.out 
echo "empty2" | tee empty2.out 


initial_hash 

# 追加されるファイル 
cd ${PROJECT_DIR}/src/eq 
touch empty4.out 
echo "empty4" | tee empty4.out 


# 監視開始 
check_state 
  echo "ready" 
  while true; do 
    for buffer in "A" "B"; do 
      # sleep $INTERVAL 
      report_arguments=( "-a" ) 
      for target in ${TARGET_DIRNAME}; do 
        cd ${PROJECT_DIR}/src/eq 
        rm empty1.out 
        rm empty3.out 
        echo "empty222" | tee empty2.out 
        # update では変わらないファイルが重要 
        update 
        watcher 
        exit 
      done 
      # ここでシェル呼ぶか判断 
      if [ ${#report_arguments[@]} -ne 1 ]; then 
        :
        counter=$(( counter + 1 )) 
      fi 
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
