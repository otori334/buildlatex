#!/bin/bash 

readonly CMDNAME=$(basename $0) 
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

. ${PROJECT_DIR}/sh/component/functions.sh 

def_state buffer 
def_state target 
def_state mode 

# initial_hash 

# 監視開始 
echo "ready" 
while true; do 
  for buffer in "A" "B"; do 
    now_time=${SECONDS} 
    # report_arguments=( "-a" ) 
    for target in ${TARGET_DIRNAME}; do 
      update 
      watcher 
    done 
    # ここでシェル呼ぶか判断 
    # if [ ${#report_arguments[@]} -ne 1 ]; then 
      # : 
      # counter=$(( counter + 1 )) 
    # fi 
    # exit 
    # comparison_time=$(( SECONDS + INTERVAL )) 
    # SECONDS < INTERVAL + now_time  ならば待つ 
    if [ $(( now_time + INTERVAL )) -gt ${SECONDS} ]; then 
      echo $(( SECONDS - now_time )) 
      sleep $(( INTERVAL - SECONDS + now_time )) 
    else 
      echo $(( SECONDS - now_time )) 
    fi 
  done 
done 
exit # 監視終了 

nowdate=`date '+%Y/%m/%d'` 
nowtime=`date '+%H:%M:%S'` 
no=`expr $no + 1` 
${PROJECT_DIR}/sh/build.sh $no $nowdate $nowtime $c& 
echo "update_hashd\nno:$no\ndate:$nowdate\ntime:$nowtime\nfile:$c\n" 
