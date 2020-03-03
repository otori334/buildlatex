#!/bin/zsh

## sh エミュレーションモード
##https://fumiyas.github.io/2013/12/03/zsh-scripting.sh-advent-calendar.html
##emulate -R sh

set -eu

PROJECT_DIR=$(cd $(dirname $0); cd ../; pwd)
cd ${PROJECT_DIR}

CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)

BUILD_DIR="/tmp/buildlatex-${CURRENT_BRANCH}"

mkdir -p "${BUILD_DIR}"
cp -R ${PROJECT_DIR}/src ${BUILD_DIR}/
cd ${BUILD_DIR}/src
mv ${BUILD_DIR}/src/template/* ${BUILD_DIR}/src
rm -rf "${BUILD_DIR}/src/template"
mv ${BUILD_DIR}/src/img/* ${BUILD_DIR}/src
rm -rf "${BUILD_DIR}/src/img"
mv ${BUILD_DIR}/src/last/* ${BUILD_DIR}/src
rm -rf "${BUILD_DIR}/src/last"

latexmk contents.tex
mv ./contents.pdf "${PROJECT_DIR}/dest/report.pdf"
##rm -rf "${BUILD_DIR}"
osascript -e 'display notification "exit tex->pdf" with title "processing"'
open -a Skim ${PROJECT_DIR}/dest/report.pdf