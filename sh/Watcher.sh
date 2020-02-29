#!/bin/sh 

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
  readonly TARGET_DIR=`find ${PROJECT_DIR}/src/ -type d -depth 1 | sed 's!^.*/!!' | sort -f` 
fi 
# 監視間隔，秒で指定 
readonly interval=1 
# 変化検後にインクリメントさせる変数 
counter=0 

# 状態変数を記録する配列 
array_state=() 

# 状態変数を定義する関数 
# 引数は二つ 
def_state () { 
  eval $1="$2" 
  # ARRAY_STATE_NAMEは状態変数の名前を格納する配列 
  ARRAY_STATE_NAME+=( $1 ) 
  # ARRAY_STATE_NUMBERはこれまでに定義された状態変数の数を格納する変数 
  ARRAY_STATE_NUMBER=${#ARRAY_STATE_NAME[@]} 
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
  PRE_IFS=${IFS}; IFS=_ 
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
rec_state () { 
  # 各状態変数をarray_stateに記録する 
  maximal=() 
  for state in ${ARRAY_STATE_NAME[@]}; do 
    eval maximal+=( $(eval echo '"${'${state}'}"') ) 
  done 
  PRE_IFS=${IFS}; IFS=_ 
    array_state+=( "$(echo "${maximal[*]}")" ) 
  IFS=${PRE_IFS} 
  # echo "${array_state[@]}" # デバッグ用 
} 

# rec_stateをさかのぼって状態変数を参照する関数 
# 記録された状態変数配列array_stateの末尾を読む
# reminiscence_state，remember_state 
rem_state () { 
  echo "${array_state[$(( ${#array_state[@]} - $1 - 1 ))]}" 
} 

# 配列名を生成する関数だった 
quaternion () { 
  rec_state 
    if [ $# -eq 0 ]; then 
      # Thanks to https://qiita.com/laikuaut/items/96dd37a8a59a87ece2ea 
      # 引数が無い場合は状態変数に対応した配列名を生成 
      # var_name="${target}_${mode}_${buffer}" 
      var_name="$(rem_state 0)" 
    else 
      # 引数で指定された配列名を生成 
      # 引数で指定する場合，全部の状態変数を変えるのは大変だから，もっと賢くしたい 
      var_name="${1}_${2}_${3}" 
    fi 
    str="var_name" 
    eval echo '$'$str 
    # eval echo '$'$str 
  rest_state 
} 

# 引数で指定された配列名を生成する関数 
spec_state () { 
  rec_state 
  
  : 
  rest_state 
} 


# 定義されるよりも前に遡る場合はデフォルト値に書き換わるようにしようかな 


# この関数が呼ばれたとき，二値の状態変数bufferが参照してないもう片方を返す関数 
xor_buffer () { 
  # -eqは文字の比較条件式に使えない 
  if [ "${buffer}" = "A" ] ; then 
    echo "B" 
  else 
    echo "A" 
  fi 
} 



# 状態変数の影響力を比べる機能を組み込みたい 
# まだ 


# グローバル変数である状態変数にスコープを与える関数，rec_stateと合わせて使う 
rest_state () { 
  # 各状態変数をarray_stateの内容に戻す関数 
  # Thanks to https://qiita.com/tommarute/items/0085e33ac9271fbd74e1 
  # アンダーバー区切りの末尾要素から要素を抽出 
  PRE_IFS=${IFS}; IFS=${ORI_IFS} 
    part=( $( rem_state 0 | tr -s '_' ' ') ) 
  IFS=${PRE_IFS} 
  # Thanks to https://qiita.com/b4b4r07/items/e56a8e3471fb45df2f59 
  # 配列の末尾要素を読んで状態変数を復元（破壊的操作）
  array_state=("${array_state[@]:0:$(( ${#array_state[@]} - 1 ))}") 
  index=0 
  for state in ${part[@]}; do 
    eval $(echo "${ARRAY_STATE_NAME[${index}]}")="${state}" 
    index=$(( index + 1 )) 
  done 
} 

def_state target TAR 
def_state mode MOD 
def_state buffer BUF 
# echo "${array_state[@]}"; rec_state; echo "${array_state[@]}"
# echo "${array_state[@]}"; rest_state; echo "${array_state[@]}"
  
# echo "終了"; exit 


# 擬4次元配列を格納する関数 
roster() { 
  # rec_state 
    if [ $# -eq 1 ]; then 
      # Thanks to https://aki-yam.hatenablog.com/entry/20081105/1225865004 
      # Thanks to https://orebibou.com/2015/01/シェルスクリプトでevalコマンドを用いた変数の2重/ 
      # Thanks to https://qiita.com/mtomoaki_96kg/items/ff82305f1ff4bb4c827c 
      eval echo '"${'$(quaternion)'['$1']}"' 
    else 
      eval echo '"${'$(quaternion $1 $2 $3)'['$4']}"' 
    fi 
  # rest_state 
} 


# target中のファイル名一覧を格納・更新する関数 
files_in () { 
  rec_state; mode="file"; rec_state; echo "${array_state[@]}" 
    # Thanks to https://aimstogeek.hatenablog.com/entry/2016/02/07/000318 
    # シェルスクリプトでfindした結果を配列で受け取る 
    # Thanks to https://qiita.com/catfist/items/ef5b6496f5ce7b0abcc2 
    # .DS_Store 無視 
    index=0 
    # Thanks to https://www.marketechlabo.com/bash-batch-best-practice/ 
    # sed 's!^.*/!!'何かわからないけど多分パスの後ろの/を削ってる・無いと動かない 
    for file in `find ${PROJECT_DIR}/src/${target} -type f -maxdepth 2 ! -name .DS_Store | sed 's!^.*/!!' | sort -n`; do 
      eval $(quaternion)[index]="${file}" 
      # echo "$(quaternion)[${index}] = ${file}" # デバッグ用 
      # echo "${array_state[@]}[${index}] = ${file}" # デバッグ用 
      # Thanks to http://unix.oskp.net/shellscript/while_until.html 
      # Thanks to https://qiita.com/d_nishiyama85/items/a117d59a663cfcdea5e4 
      index=$(( index + 1 )) 
    done 
  rest_state; rest_state; echo "${array_state[@]}"  # mode 
} 

# ハッシュ値を更新する関数 
update_hash () { 
  # Thanks to https://qiita.com/tamanobi/items/74b62e25506af394eae5 
  echo `openssl sha256 -r $1 | awk '{print $1}'` 
} 

# ハッシュ値一覧を4次元配列に格納・更新する関数 
update () { 
  rec_state; mode="hash"; rec_state; echo "${array_state[@]}" 
    # ファイル名一覧を格納・更新 
    files_in 
    cd ${PROJECT_DIR}/src/${target} 
    index=0 
    for file in $(roster ${target} "file" ${buffer} @); do 
      # Thanks to https://qiita.com/laikuaut/items/96dd37a8a59a87ece2ea 
      # bashで文字列を変数名に展開する方法 
      eval $(quaternion)[index]=`update_hash ${file}` 
      # echo "$(quaternion)[${index}] = $(roster ${index})" # デバッグ用 
      # echo "${array_state[@]}[${index}] = $(roster ${index})" # デバッグ用 
      index=$(( index + 1 )) 
    done 
  rest_state; rest_state; echo "${array_state[@]}"  # mode 
} 

# ハッシュ値の初期値を取得する関数 
initial_hash () { 
  rec_state; buffer="B"; rec_state; echo "${array_state[@]}" 
    for target in ${TARGET_DIR}; do 
      rec_state; echo "${array_state[@]}"  # target 
        update 
      rest_state; echo "${array_state[@]}"  # target 
    done 
  rest_state; rest_state; echo "${array_state[@]}"  # buffer 
} 

array_diff_a () { 
  rec_state; mode="hash"; rec_state; echo "${array_state[@]}" 
    
    if [ "$(roster @)" != "$(roster ${target} ${mode} $(xor_buffer) @)" ] ; then 
      echo "ハッシュが変わった場合" 
      # array_diff_b
      array_diff_b
    else 
      echo "ハッシュが変わらない場合" 
    fi
  rest_state; rest_state; echo "${array_state[@]}"  # mode 
}

# ファイルの変更を検知する関数 
array_diff_b () { 
  rec_state; mode="hash"; rec_state; echo "${array_state[@]}" 
    previous_index=$(eval echo '${#'$(quaternion ${target} ${mode} $(xor_buffer))'[@]}')
    current_index=$(eval echo '${#'$(quaternion)'[@]}')
    echo "${array_state[@]} P${previous_index}\n${array_state[@]} C${current_index}" # デバッグ用 
    
    array_diff_d
    echo "終了"; exit
    
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
  rest_state; rest_state; echo "${array_state[@]}"  # mode 
}

array_diff_c () { 
  :
}

# 配列を比較する関数
# 直前の状態変数を記録したい
array_diff_d () { 
  pre_mode=${mode};
  rec_state; mode="uniq"; rec_state; echo "${array_state[@]}" 
    PRE_IFS=${IFS} 
    IFS=$'\n' 
    # echo "${array_state[$(( ${#array_state[@]} - 2 ))]}"
    echo ああああああ
    rem_state 0
    rem_state 1
    rem_state 2
    rem_state 3
    exit
    
    
    # Thanks to https://anmino.hatenadiary.org/entry/20091020/1255988532 
    # Thanks to https://qiita.com/mtomoaki_96kg/items/ff82305f1ff4bb4c827c
    both=(`{ echo "$(roster ${target} ${pre_mode} ${buffer} \*)"; echo "$(roster ${target} ${pre_mode} $(xor_buffer) \*)"; } | sort | uniq -d`) 
    # previous_uniq=($({ echo "${both[*]}"; echo "$(roster ${target} ${mode} $(xor_buffer) \*)"; } | sort | uniq -u)) 
    eval $(quaternion ${target} ${mode} $(xor_buffer))="($({ echo "${both[*]}"; echo "$(roster ${target} ${pre_mode} $(xor_buffer) \*)"; } | sort | uniq -u)) "
    # current_uniq=($({ echo "${both[*]}"; echo "$(roster ${target} ${mode} ${buffer} \*)"; } | sort | uniq -u)) 
    eval $(quaternion)="($({ echo "${both[*]}"; echo "$(roster ${target} ${pre_mode} ${buffer} \*)"; } | sort | uniq -u)) "
    echo "both\n${both[*]}\nprevious\n$(roster ${target} ${mode} $(xor_buffer) \*)\ncurrent\n$(roster \*)" # デバッグ用
    echo "$(xor_buffer)_uniq\n${B_uniq[*]}\n$(quaternion)\n${A_uniq[*]}" # デバッグ用
    
    exit
    # eval $(xor_buffer)_uniq= 
    # eval ${buffer}_uniq="${file}" 
    # eval $(quaternion)[index]="$file" 
    IFS=${PRE_IFS} 
  rest_state; rest_state; echo "${array_state[@]}"  # mode 
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

# cd ${PROJECT_DIR}/src/eq
# touch empty1.out
cd ${PROJECT_DIR}/src/eq
touch empty1.out
initial_hash 
# rm empty1.out

# 監視開始 
rec_state; echo "${array_state[@]}" 
  while true; do 
    while true; do 
      while true; do 
        for buffer in "A" "B"; do 
          rec_state; echo "${array_state[@]}" # buffer 
            # sleep $interval 
            for target in ${TARGET_DIR}; do 
              rec_state; echo "${array_state[@]}"  # target 

                cd ${PROJECT_DIR}/src/eq
                rm empty1.out
                
                update                 
                array_diff_a
                exit
                # array_diff_b 
              rest_state; echo "${array_state[@]}"  # target 
            done
            # roster @ 
            # echo "" 
          rest_state; echo "${array_state[@]}"  # buffer 
          exit 
        done
      done
      exit
    done 
  done 
rest_state; echo "${array_state[@]}"  # 監視終了 
exit

#eval  ${PROJECT_DIR}/sh/build.sh　aaaaaaaa
nowdate=`date '+%Y/%m/%d'`
nowtime=`date '+%H:%M:%S'`
no=`expr $no + 1`
${PROJECT_DIR}/sh/build.sh $no $nowdate $nowtime $c&
#${PROJECT_DIR}/sh/test.sh $no $nowdate $nowtime $c&
echo "update_hashd\nno:$no\ndate:$nowdate\ntime:$nowtime\nfile:$c\n"

