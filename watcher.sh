#!/bin/bash 

# 監視間隔を秒で指定 
readonly INTERVAL=1 
readonly PROJECT_DIR="$(cd "$(dirname "$0")"; pwd)" 
readonly CURRENT_BRANCH="$(cd "${PROJECT_DIR}"; git rev-parse --abbrev-ref HEAD)" 
readonly BRANCH_DIR="/tmp/buildlatex_${CURRENT_BRANCH}" 
readonly CACHE_DIR="${BRANCH_DIR}/cache" 
readonly TARGET_DIRNAME="${1:-src}" 
IFS=$'\n' 
no=0 
trap 'echo "end watcher.sh" && rm -rf "${BUILD_DIR}" && exit' 0 1 2 3 15 

function setup() { 
  build_flag=0 
  dir_index=0 
  max_depth=0 
  depth=0 
} 

function unset_depth() { 
  for ((depth=${max_depth}; depth>0; depth--)); do 
    unset path_${depth} key_${depth} 
  done 
} 

function glance() { 
  cd "$1" 
  if [ $((++depth)) -gt ${max_depth} ]; then 
    max_depth=${depth} 
  fi 
  for _sub_dirname in $(ls -p | grep /$); do 
    glance "${_sub_dirname}" 
  done 
  eval path_${depth}+='('"$(pwd)"')' 
  eval key_${depth}+='('"$1"')' 
  ((depth--)) 
  cd ../ 
} 

function watch() { 
  cd "$1" 
  if [ $((++depth)) -gt ${max_depth} ]; then 
    max_depth=${depth} 
  fi 
  local _build_flag=${build_flag} 
  for _sub_dirname in $(ls -Ap | grep /$); do 
    watch "${_sub_dirname}" 
  done 
  local _list_file="$(ls -Ap | grep -v /$ 2> /dev/null)" 
  local _hash="$(shasum -a 256 ${_list_file:-./} 2> /dev/null | shasum -a 256)" 
  ((dir_index++)) 
  if [ "${_hash}" != "${buffer[${dir_index}]:=${_hash}}" ]; then 
    buffer[${dir_index}]="${_hash}" 
    ((build_flag++)) 
  fi 
  if [ ${_build_flag} -ne ${build_flag} ]; then 
    eval path_${depth}+='('"$(pwd)"')' 
    eval key_${depth}+='('"$1"')' 
  fi 
  ((depth--)) 
  cd ../ 
} 

function build() { 
  local _build_pid=$(bash -c 'echo ${PPID}') 
  BUILD_DIR="${BRANCH_DIR}/${_build_pid}" 
  mkdir -p "${BUILD_DIR}" 
  cp -R "${CACHE_DIR}/${TARGET_DIRNAME}" "${BUILD_DIR}/" 2> /dev/null || cp -R "${PROJECT_DIR}/${TARGET_DIRNAME}" "${BUILD_DIR}/" 
  for ((depth=${max_depth}; depth>0; depth--)); do 
    local _max_index=$(eval echo '"${#'path_${depth}'[*]}"') 
    for ((_index=0; _index<${_max_index}; _index++)); do 
      processing ${depth} ${_index} & 
    done 
    # 全部の処理が終わるまで上位の処理に移らないから，同じ重さの処理は深さを揃えた方がいい 
    wait 
  done 
  rm -rf "${CACHE_DIR}" 
  mv "${BUILD_DIR}" "${CACHE_DIR}/" 
  if [ ${no} -eq 0 ]; then 
    echo "open Skim" 
    open -a Skim "${PROJECT_DIR}/dest/output.pdf" 
  fi 
  # osascript -e 'display notification "processing md->pdf" with title "exit"' 
  echo "Run number ${no} finished" 
  exit 
} 

function processing() { 
  eval path='${path_'$1'['$2']:-/ERROR_PROCESSING}' 
  eval key='${key_'$1'['$2']}' 
  # 危ない-> "rm -f *.tex ../*.tex" カレントディレクトリで実行しないように注意 
  cd "${BUILD_DIR:-/ERROR_PROCESSING}${path#${PROJECT_DIR}}" || exit 1 
  case "${key}" in 
    "eq/" ) 
      mv "../automatic_generated.tex" "../automatic_generated.tex-bak" 2> /dev/null 
      rm -f *.tex ../*.tex 
      mv "../automatic_generated.tex-bak" "../automatic_generated.tex" 2> /dev/null 
      cp "${path}/"*.tex ./ # 2> /dev/null 
      for _filename in *.tex; do 
        sed -i '' -e "s/\\label{}/\\label{${_filename%.*}}/g" "${_filename}" 
      done 
      cp *.tex ../ # 2> /dev/null 
      exit ;; 
    "fig/" ) 
      rm -f ../*.{png,jpg,pdf} 
      cp "${path}/"*.{png,jpg,pdf} ../ 2> /dev/null 
      exit ;; 
    "md/" ) 
      rm -f *.{md,bib} 
      cp "${path}/"*.{md,bib} ./ 2> /dev/null 

      # Thanks to https://yanor.net/wiki/?シェルスクリプト/sedでバックスラッシュを置換する際の注意点 
      # LaTeX の強制改行 "\\" を Pandoc が "\" のエスケープと判断するのを防ぐ 
      sed -i '' \
      -e 's/\\\\/\\mymynewline/g' \
      -e 's/\\,/\\mymysmallspace/g' \
      -e 's/\\begin{comment}/<!--/g' \
      -e 's/\\end{comment}/-->/g' \
      *.md 
                            
      pandoc *.md -N -o automatic_generated.tex \
      -F pandoc-crossref \
      --template=./boilerplate.tex \
      --pdf-engine=lualatex \
      -V documentclass=ltjsarticle \
      -V luatexjapresetoptions=hiragino-pron-W4 \
      -V indent=true \
      --toc \
      --toc-depth=2 \
      -M "crossrefYaml=./config.yml" 

      # pandoc に解釈されないように書き換えてた LaTeX 風の書き方を元に戻す 
      sed -i '' \
      -e 's/\\mymysmallspace/\\,/g' \
      -e 's/\\mymynewline/\\\\/g' \
      -e 's/\\cite\\{/~\\cite/g' \
      -e 's/null//g' \
      -e 's/。/．/g' \
      -e 's/、/，/g' \
      -e 's/\\%/%/g' \
      -e 's/includegraphics/includegraphics[width=1.0\\columnwidth]/g' \
      -e 's/begin{figure}/begin{figure}[htb]/g' \
      automatic_generated.tex 
      
      cp automatic_generated.tex "${PROJECT_DIR}/dest/contents.tex" 
      cp automatic_generated.tex ../ 
      exit ;; 
    "tpl/" ) 
      cp "${path}/"{*,.*} ../ 2> /dev/null 
      exit ;; 
    * ) 
      case "$1" in 
        1 ) 
          rm -f automatic_generated.pdf 
          latexmk || { 
            echo "error state $?" 
            osascript -e 'display notification "something went wrong" with title "latexmk"' 
          } 
          cp automatic_generated.pdf "${PROJECT_DIR}/dest/output.pdf" 2> /dev/null 
          exit ;; 
        * ) 
          echo "ERROR" 
          exit ;; 
      esac 
  esac 
} 

setup 
glance "${PROJECT_DIR}/${TARGET_DIRNAME}" 
build_flag=1 

while true; do 
  if [ ${build_flag} -ne 0 ]; then 
    build & 
    ((no++)) 
    unset_depth 
  fi 
  sleep ${INTERVAL} 
  setup 
  watch "${PROJECT_DIR}/${TARGET_DIRNAME}" 
  if [ ${dir_index} -ne ${max_dir_index:=${dir_index}} ]; then 
    max_dir_index=${dir_index} 
    unset buffer 
    unset_depth 
    build_flag=0 
  fi 
done 