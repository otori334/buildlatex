#!/bin/bash 

set -u 
export PROJECT_DIR 
export TARGET_DIRNAME 
export BRANCH_DIR 
export BUILD_DIR 
readonly PROJECT_DIR=$(cd $(dirname $0); cd ../; pwd) 
readonly CURRENT_BRANCH=$(cd ${PROJECT_DIR}; git rev-parse --abbrev-ref HEAD) 
readonly TARGET_DIRNAME=${TARGET_DIRNAME:-shot} 
readonly NO=${no:-1} 
readonly ID=$(date '+%d%H%M%S')$((RANDOM%+101)) 
readonly BRANCH_DIR="/tmp/buildlatex_${CURRENT_BRANCH}" 
readonly BUILD_DIR="${BRANCH_DIR}/${TARGET_DIRNAME}_${ID}" 
trap 'rm -rf ${BUILD_DIR}' 1 2 3 15 && mkdir -p ${BUILD_DIR} 
cp -R ${PROJECT_DIR}/src ${BUILD_DIR}/ 
cp -R ${BRANCH_DIR}/cache/* ${BUILD_DIR}/src/ || { 
  echo "mkdir cache" 
  mkdir -p ${BRANCH_DIR}/cache 
} 
# ドットファイルをワイルドカードに含めるように設定 
# Thanks to https://www.denet.ad.jp/technology/2018/10/cpcommand.html 
shopt -s dotglob 


# ディレクトリ構成を再帰的に溶かす危険な関数．取り扱い注意 
function deploy_file() { 
  cd $1 
  for _sub_dirname in $(ls -F | grep /); do 
    deploy_file ${_sub_dirname} 
  done 
  # processing.sh という名前のファイルがあれば実行 
  if [ -e processing.sh ]; then 
    ./processing.sh 
    rm -f processing.sh 
  fi 
  # mv も processing.sh に含める予定 
  mv * ../ 
  cd ../ 
  rm -rf $1 
} 

deploy_file ${BUILD_DIR}/src 

mv ${BUILD_DIR}/automatic_generated.pdf ${PROJECT_DIR}/dest/output.pdf 
# 中間生成ファイルを保存する 
cp -R automatic_generated.* ../cache/ 
rm -rf ${BUILD_DIR} 
if [ ${NO} -eq 0 ]; then 
  echo "open Skim" 
  open -a Skim ${PROJECT_DIR}/dest/output.pdf 
fi 
# osascript -e 'display notification "processing md->pdf" with title "exit"' 
