#!/bin/bash 

readonly CMDNAME=$(basename $0) 
readonly PROJECT_DIR=$(cd $(dirname $0); cd ../; pwd) 
. ${PROJECT_DIR}/sh/component/functions.sh 
CURRENT_BRANCH=$(cd ${PROJECT_DIR}; git rev-parse --abbrev-ref HEAD) 

readonly no=${no:-1} 
export TARGET_DIRNAME=${TARGET_DIRNAME:-one_shot} 
export BUILD_DIR="/tmp/buildlatex_${CURRENT_BRANCH}/${TARGET_DIRNAME}/${no}" 
mkdir -p "${BUILD_DIR}" 
cp -R ${PROJECT_DIR}/src ${BUILD_DIR}/ 


if [ ${no} -eq 1 ]; then 
  deploy_file ${BUILD_DIR}/src 
else
  : 
fi 

# deploy_file 
# echo "終了" 

echo ${no} 
