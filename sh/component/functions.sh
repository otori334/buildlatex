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

# target中のファイル名一覧を格納・更新する関数 
function files_in () { 
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
  mode="hash"; debug 2 
  # ファイル名一覧を格納・更新 
  files_in 
  # if [ $# -eq 1 ] ; then 
    local _vision_update=( $(roster $(mode="file"; read_state) @) )
  # else 
    # local _PRE_IFS=${IFS}; IFS=$'\n' 
      # 既にファイル名とハッシュ値が結びついている要素はハッシュ値を新しく計算しない 
      # ハッシュ値が変化していなかったファイル名の重複を取り除き格納 
      # local _vision_update=( $({ 
        # roster $(mode="file"; read_state) @; 
        # roster $(buffer=buffer; mode=steady; read_state) '*'; 
      # } | sort | uniq -u ) ) 
    # IFS=${_PRE_IFS} 
  # fi 
  cd ${PROJECT_DIR}/src/${target} 
  local _index_update=0 
  local _file_update=0 
  for _file_update in ${_vision_update[@]}; do 
  # for _file_update in $(roster $(mode="file"; read_state) @); do 
    # Thanks to https://qiita.com/laikuaut/items/96dd37a8a59a87ece2ea 
    # bashで文字列を変数名に展開する方法 
    eval $(read_state)[${_index_update}]=$(update_hash ${_file_update}) 
    eval _$(roster ${_index_update})="${_file_update}" 
    debug 3 update ${_index_update} 
    _index_update=$(( _index_update + 1 )) 
  done 
  return 0 
} 

# ハッシュ値の初期値を取得する関数 
function initial_hash () { 
  check_state 
    buffer="B"; debug 2 
    for target in ${TARGET_DIRNAME}; do 
      debug 2 
      update 0 
    done 
  rest_state 
  return 0 
} 

function watcher () { 
  # check_state 
    mode="hash"; debug 2 
    # 変化した場合 
    # if [ "$(roster)" != "$(roster $(xor_buffer; read_state) @)" ] ; then 
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
        # local _steady_watcher=$(buffer=buffer; mode=steady; read_state) 
        local _filename_watcher=0 
        # local _index_watcher=0 
        # for _filename_watcher in ${_unchanged_filehash[@]}; do 
          # eval $(echo ${_steady_watcher})[${_index_watcher}]=$(eval echo '"${_'${_filename_watcher}'}"') 
          # _index_watcher=$(( _index_watcher + 1 )) 
        # done 
        # 追加されたファイルのハッシュ値（ _added_filehash ）を検索 
        local _vision_watcher=0 
        local _added_filehash=() 
        _index_watcher=0 
        for _filename_watcher in ${_added_filename[@]}; do 
          _vision_watcher="${buffer}_$(echo "${_filename_watcher}" | tr '\,' '_' | tr '\.' '_' )" 
          _added_filehash+=( $(roster ${_vision_watcher}) ) 
          # eval unset "${_vision_watcher}" 
        done 
        # 上書きすべきファイルのハッシュ値（ _overwrite_filehash ）を割り出す 
        local _overwrite_filehash=( $({ 
          echo "${_unchanged_filehash[*]}"; 
          roster '*'; 
        } | sort | uniq -u) ) 
        # 上書きすべきファイル名（ _overwrite_filename ）を検索し格納 
        local _overwrite_filename=() 
        for _filename_watcher in ${_overwrite_filehash[@]}; do 
          _overwrite_filename+=( $(eval echo '"${_'${_filename_watcher}'}"') ) 
          # eval unset "_${_filename_watcher}" 
        done 
        # 更新されたファイル名（ _changed_filename ）を割り出す 
        local _changed_filename=( $({ 
          echo "${_added_filename[*]}"; 
          echo "${_overwrite_filename[*]}"; 
        } | sort | uniq -u) ) 
        
        # echo "消えるファイル"
        # echo "${#_erased_filename[@]}"
        echo "${_erased_filename[@]}"
        # echo "更新されたファイル"
        # echo "${#_changed_filename[@]}"
        echo "${_changed_filename[@]}"
        # echo "追加されるファイル"
        # echo "${#_added_filename[@]}"
        echo "${_added_filename[@]}"
        # echo "上書きすべきファイル"
        # echo "${#_overwrite_filename[@]}"
        echo "${_overwrite_filename[@]}"
        
        
        # debug 1 watcher 
        
        # rm empty4.out; rm empty2.out; echo "終了";debug 2; exit # 変わるファイルを消す 
        
        
        # ${PROJECT_DIR}/sh/build.sh& 
        # フラグのために変更されたファイルを求める
        
        # report_arguments+=( "${target}") 
        
        
      IFS=${_PRE_IFS} 
    # else 
      # echo "ハッシュが変わらない場合" 
      : 
    # fi 
    # no=334
    
    # update では変わらないファイルの名前が重要 
    
    # 渡したい状態　消去と変化同時　消去のみ　変化のみ 
    # それぞれの要素の数 
    
    # ${PROJECT_DIR}/sh/test.sh $no ${_erased_filename[@]}& 
    # ${PROJECT_DIR}/sh/build.sh $no $nowdate $nowtime $c& 
    
    # echo "${unchanged_files1[@]}" 
    # rm empty4.out; rm empty2.out; echo "終了";debug 2; exit # 変わるファイルを消す 

  # rest_state 
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