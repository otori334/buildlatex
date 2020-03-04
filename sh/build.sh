#!/bin/bash 

echo $@ 
exit
# echo "終了"

# sleep 10

readonly CMDNAME=$(basename $0) 
readonly PROJECT_DIR=$(cd $(dirname $0); cd ../; pwd) 
. ${PROJECT_DIR}/sh/component/functions.sh 
usage () {
  : 
} 
# 引数処理 

echo $@ 

# echo "${buffer_eq_erased[@]}" 

