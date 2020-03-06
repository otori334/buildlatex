#!/bin/bash 

set -u 
export PROJECT_DIR=$(cd $(dirname $0); cd ../; pwd) 
. ${PROJECT_DIR}/sh/component/functions.sh 

readonly CURRENT_BRANCH=$(cd ${PROJECT_DIR}; git rev-parse --abbrev-ref HEAD) 
export TARGET_DIRNAME=${TARGET_DIRNAME:-shot} 
readonly no=${no:-1} 
export BRANCH_DIR="/tmp/buildlatex_${CURRENT_BRANCH}" 
export BUILD_DIR="/${BRANCH_DIR}/${TARGET_DIRNAME}_${no}" 
cp -R ${BRANCH_DIR}/cache ${BUILD_DIR} || mkdir -p ${BUILD_DIR} 
trap 'rm -rf ${BUILD_DIR}' 1 2 3 15 
cp -R ${PROJECT_DIR}/src ${BUILD_DIR}/ 

# ドットファイルをワイルドカードに含めるように設定 
# Thanks to https://www.denet.ad.jp/technology/2018/10/cpcommand.html 
shopt -s dotglob 
# これはディレクトリを再帰的に溶かす危険な関数．取り扱い注意 
deploy_file ${BUILD_DIR}/src 
# 中間生成ファイルを保存する 
cp -R automatic_generated.* ../cache/ || mkdir -p ${BRANCH_DIR}/cache; cp -R automatic_generated.* ../cache/ 
rm -rf ${BUILD_DIR} 
if [ ${no} -eq 1 ]; then 
  open -a Skim ${PROJECT_DIR}/dest/output.pdf 
fi 
osascript -e 'display notification "processing md->pdf" with title "exit"' 
