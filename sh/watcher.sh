#!/bin/bash 

# 監視間隔を秒で指定 
readonly INTERVAL=1 
readonly CMDNAME=$(basename $0) 
readonly PROJECT_DIR=$(cd $(dirname $0); cd ../; pwd) 
. ${PROJECT_DIR}/sh/component/functions.sh 
usage () { 
  echo "src直下の，指定されたディレクトリ内の変更後にbuild.shを実行します．" 
  echo "引数がない場合，mdを監視します．" 
  echo "${CMDNAME}は高速ですがファイルの増減に反応しません．" 
} 
# 引数処理 
if [ $# -le 1 ]; then 
  if [ $# = 1 ]; then 
    if [ -d ${PROJECT_DIR}/src/$1 ]; then 
      readonly TARGET_DIR=${PROJECT_DIR}/src/$1 
    else 
      usage 
      exit 1 
    fi 
  else 
    readonly TARGET_DIR=${PROJECT_DIR}/src/md 
  fi 
else 
  usage 
  echo "複数のディレクトリを監視するにはmanager.shを使うか，${CMDNAME}を並列に実行してください．" 
  exit 1 
fi 
cd ${TARGET_DIR} 
# trap '(kill $(jobs -p))||:' EXIT TERM 
# 変化検知毎にインクリメントさせる変数 
export counter=1 
export filename=0 
def_state buffer "A" 
initial_hash 
number_of_files=$(ls -U1 | wc -l) 
xor_buffer 
while true 
do 
  index=0 
  for filename in * 
  do 
    eval $(read_state)[${index}]=$(update_hash ${filename}) 
    if [ "$(roster $(xor_buffer; read_state) ${index})" != "$(roster ${index})" ]; then 
      if [ ${number_of_files} -eq $(ls -U1 | wc -l) ]; then 
        ${PROJECT_DIR}/sh/build.sh & 
        counter=$(( counter + 1 )) 
      else 
        initial_hash 
        number_of_files=$(ls -U1 | wc -l) 
        # echo "aaaaaaaaaaoooooooooooooooooooooooooo" 
      fi 
      xor_buffer 
      break 1 
    fi 
    index=$(( index + 1 )) 
  done 
  sleep INTERVAL 
done 
