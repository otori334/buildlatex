#!/bin/sh 

# 区切り文字の設定を保存 
# Thanks to http://capm-network.com/?tag=シェルスクリプト-スペースが含まれる文字列を扱う 
readonly ORI_IFS=${IFS} 
# 区切り文字の設定を一時保存する変数 
PRE_IFS=${ORI_IFS} 
## 実行スクリプトの保管 
readonly PID=$$ 
## パスの保管 
readonly PROJECT_DIR=$(cd $(dirname $0); cd ../; pwd) 
readonly CURRENT_BRANCH=$(cd ${PROJECT_DIR}; git rev-parse --abbrev-ref HEAD) 
# 引数処理 
if [ $# -ne 0 ]; then 
  # 引数で注目するディレクトリ（TARGET_DIR）を指定 
  readonly TARGET_DIR=$@ 
else 
  # 引数がなければsrc内すべてのディレクトリを監視 
  readonly TARGET_DIR=`find ${PROJECT_DIR}/src/ -type d -depth 1 | sed 's!^.*/!!' | sort -f` 
fi 
# 監視間隔，秒で指定 
readonly interval=1 
# 変化検後にインクリメントさせる変数 
orbit=0 
# 状態変数の初期値 
target="TAR" 
mode="MOD" 
buffer="BUF" 
# 状態変数を記録する配列 
ver_state=() 

# この関数が呼ばれたとき，二値の状態変数bufferが参照してないもう片方を返す関数 
counter () {
  # -eqは文字の比較条件式に使えない 
  if [ "${buffer}" = "A" ] ; then 
    echo "B" 
  else 
    echo "A" 
  fi 
}

# グローバル変数である状態変数にスコープを与える関数 
rec_state () { 
  # 各状態変数をver_stateに記録する 
  ver_state+=( $(quaternion) )
  echo "${ver_state[@]}" # デバッグ用 
} 

# グローバル変数である状態変数にスコープを与える関数，rec_stateと合わせて使う 
rest_state () { 
  # 各状態変数をver_stateの内容に戻す関数 
  # IFS=$'\n' のあとでは要素の抽出ができなくなる 
  PRE_IFS=${IFS} 
  IFS=${ORI_IFS} 
  # Thanks to https://www.marketechlabo.com/bash-batch-best-practice/ 
  # アンダーバー区切りのファイル名から要素を抽出 
  part=( $(echo "${ver_state[$(( ${#ver_state[@]} - 1 ))]}" | tr -s '_' ' ') ) 
  IFS=${PRE_IFS} 
  # Thanks to https://qiita.com/b4b4r07/items/e56a8e3471fb45df2f59 
  # 配列の末尾要素を読んで状態変数を復元（破壊的操作）
  ver_state=("${ver_state[@]:0:$(( ${#ver_state[@]} - 1 ))}") 
  target="${part[0]}" 
  mode="${part[1]}" 
  buffer="${part[2]}" 
  echo "${ver_state[@]}" # デバッグ用 
} 

# 配列名を生成する関数 
quaternion () { 
  if [ $# -eq 0 ]; then 
    # Thanks to https://qiita.com/laikuaut/items/96dd37a8a59a87ece2ea 
    # 引数が無い場合は状態変数に対応した配列名を生成 
    var_name="${target}_${mode}_${buffer}" 
  else 
    # 引数で指定された配列名を生成 
    var_name="${1}_${2}_${3}" 
  fi 
  str="var_name" 
  eval echo '$'$str 
} 

# 擬4次元配列を格納する関数 
roster() { 
  if [ $# -eq 1 ]; then 
    # Thanks to https://aki-yam.hatenablog.com/entry/20081105/1225865004 
    # Thanks to https://orebibou.com/2015/01/シェルスクリプトでevalコマンドを用いた変数の2重/ 
    # 引数が一つの場合 
    eval echo '${'$(quaternion)'['$1']}' 
  else 
    eval echo '${'$(quaternion $1 $2 $3)'['$4']}' 
  fi 
} 

# target中のファイル名一覧を格納・更新する関数 
files_in () { 
  rec_state; mode="file"; rec_state 
    # Thanks to https://aimstogeek.hatenablog.com/entry/2016/02/07/000318 
    # シェルスクリプトでfindした結果を配列で受け取る 
    # Thanks to https://qiita.com/catfist/items/ef5b6496f5ce7b0abcc2 
    # .DS_Store 無視 
    index=0 
    # Thanks to https://www.marketechlabo.com/bash-batch-best-practice/
    # sed 's!^.*/!!'何かわからないけど多分パスの後ろの/を削ってる・無いと動かない
    for file in `find ${PROJECT_DIR}/src/${target} -type f -maxdepth 2 ! -name .DS_Store | sed 's!^.*/!!' | sort -n`; do 
      eval $(quaternion)[index]="$file" 
      # echo "$(quaternion)[${index}] = ${file}" # デバッグ用 
      # echo "${ver_state[@]}[${index}] = ${file}" # デバッグ用 
      # Thanks to http://unix.oskp.net/shellscript/while_until.html 
      # Thanks to https://qiita.com/d_nishiyama85/items/a117d59a663cfcdea5e4 
      index=$(( index + 1 )) 
    done 
  rest_state; rest_state # mode 
} 

# ハッシュ値を更新する関数 
update_hash () { 
  # Thanks to https://qiita.com/tamanobi/items/74b62e25506af394eae5 
  echo `openssl sha256 -r $1 | awk '{print $1}'` 
} 

# ハッシュ値一覧をrosterの擬4次元配列に格納・更新する関数 
update () { 
  rec_state; mode="hash"; rec_state 
    # ファイル名一覧を格納・更新 
    files_in
    cd ${PROJECT_DIR}/src/${target} 
    index=0 
    for file in $(roster ${target} "file" ${buffer} @); do 
      # Thanks to https://qiita.com/laikuaut/items/96dd37a8a59a87ece2ea 
      # bashで文字列を変数名に展開する方法 
      eval $(quaternion)[index]=`update_hash ${file}` 
      # echo "$(quaternion)[${index}] = $(roster ${index})" # デバッグ用
      # echo "${ver_state[@]}[${index}] = $(roster ${index})" # デバッグ用
      index=$(( index + 1 ))
    done 
    # 最大のindex，つまりハッシュ値生成に用いたファイルの個数を記録する連想配列 
    # 本来変数targetが入る第一項は，targetの初期値であるTARで塗り潰した
    # 配列として参照しやすい第四項にtargetを格納し，三次元連想配列風な使い方をしている
    pre_target=${target}; 
    rec_state; target="TAR" mode="index"; rec_state 
      eval $(quaternion)[target]=${index} 
      # echo "${ver_state[@]}[${pre_target}] = $(roster ${pre_target})" # デバッグ用
    rest_state; rest_state # mode 
  rest_state; rest_state # mode 
}

# ハッシュ値の初期値を取得する関数
initial_hash () { 
  rec_state; buffer="B"; rec_state 
    for target in ${TARGET_DIR}; do 
      rec_state # target 
        update 
      rest_state # target 
    done 
  rest_state; rest_state # buffer 
}

array_diff_a () { 
  if [ "buffer=0; echo $(roster @)" -eq "buffer=1; echo $(roster @)" ] ; then
    :
  fi
  if [ "${current[${b}]}" != "${last[${b}]}" ] ; then
    break 1
  fi

}

array_diff_b () { 
  rec_state; mode="hash"; rec_state 
    PRE_IFS=${IFS} 
    IFS=$'\n' 
    
    # Thanks to https://anmino.hatenadiary.org/entry/20091020/1255988532 
    #両方の配列に含まれる項目を抜き出す 
    both=(`{ echo "$(roster @)"; echo "$(roster ${target} ${mode} $(counter) @)"; } | sort | uniq -d`) 
    echo "${both[@]}" 
    #array1から重複部分を取り除くとarray1には含まれるがarray2には含まれない項目を取り出せる 
    only=(`{ echo "${both[@]}"; echo "$(roster ${target} ${mode} $(counter) @)"; } | sort | uniq -u`) 
    echo "${only[@]}" 
    # 寝て起きたら増えたときと減ったときと変わらない時で場合わけしたい
    # 後タッチでテストまだやってない
    IFS=${PRE_IFS} 
  rest_state; rest_state # mode 
}
# array_diff_b
# exit


array_diff_c () { 
  :
}

processing () {  
  index=0
  until [ $index -eq 10 ]; do
    index=$(( index + 1 ))  
    echo $index
  done
  exit
}

initial_hash 
rec_state # 監視開始 
  while true; do 
    while true; do 
      while true; do 
        for buffer in "A" "B"; do 
          rec_state # buffer 
            # sleep $interval 
            for target in ${TARGET_DIR}; do 
              rec_state # target 
                update 
                array_diff_b 
                exit
              rest_state # target 
            done
            # roster @ 
            # echo "" 
          rest_state # buffer 
          exit 
        done
      done
      exit
    done 
  done 
rest_state # 監視終了 
exit


                while true; do
                  sleep $INTERVAL
                  for f in *.md
                    do
                      b=`arraynum ${f}`
                      current[${b}]=`update_hash ${f}`
                      if [ "${current[${b}]}" != "${last[${b}]}" ] ; then
                        c=`expr ${b} - 1`.md
                        break 2
                      fi
                    done
                done                    
                  
                for f in *.md
                  do
                    b=`arraynum ${f}`
                    last[$b]="${current[${b}]}"
                    echo last_sha256_"${b}","${last[${b}]}"
                  done
                #eval  ${PROJECT_DIR}/sh/build.sh　aaaaaaaa
                nowdate=`date '+%Y/%m/%d'`
                nowtime=`date '+%H:%M:%S'`
                no=`expr $no + 1`
                ${PROJECT_DIR}/sh/build.sh $no $nowdate $nowtime $c&
                #${PROJECT_DIR}/sh/test.sh $no $nowdate $nowtime $c&
                echo "update_hashd\nno:$no\ndate:$nowdate\ntime:$nowtime\nfile:$c\n"
done
