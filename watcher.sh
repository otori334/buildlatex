#!/bin/bash 

readonly INTERVAL=1 
readonly DEST_DIRNAME="dest" 
readonly CACHE_DIRNAME="cache" 
readonly TARGET_DIRNAME="${1:-src}" 
readonly TMP_DIR="/tmp" 
readonly PROJECT_DIR="$(cd "$(dirname "$0")"; pwd)" 
readonly PROJECT_DIRNAME="$(echo "${PROJECT_DIR}" | sed -e 's/.*\/\([^\/]*\)$/\1/')" 
readonly GIT_BRANCHNAME="$(cd "${PROJECT_DIR}"; git rev-parse --abbrev-ref HEAD)" 
readonly BRANCH_DIR="${TMP_DIR}/${PROJECT_DIRNAME}_${TARGET_DIRNAME}_${GIT_BRANCHNAME}" 
readonly DEST_DIR="${PROJECT_DIR}/${DEST_DIRNAME}" 
readonly CACHE_DIR="${BRANCH_DIR}/${CACHE_DIRNAME}" 
readonly TARGET_DIR="${PROJECT_DIR}/${TARGET_DIRNAME}" 
trap 'echo "end watcher.sh" && rm -rf "${BUILD_DIR}" && exit' 0 1 2 3 15 
cd "${DEST_DIR}" 2> /dev/null || mkdir -p "${DEST_DIR}" 
cd "${TARGET_DIR}" || exit 1 
. "${PROJECT_DIR}/processing.sh" || exit 1 

function input_array2 () { 
    eval array2_$1[$2]='"'$3'"' 
} 

function output_array2 () { 
    eval echo '${array2_'$1'['$2']}' 
} 

function max_array2 () { 
    eval echo '"${#'array2_$1'[*]}"' 
} 

if [ ${INTERVAL} -gt 1 ]; then 
    # ls はタイムスタンプの粒度が秒だから，1秒以下の変化を捉えるのには力不足 
    # 監視対象が膨大な場合に有効 
    function update () { 
        ls -l | shasum -a 256 
    } 
else 
    function update () { 
        local _list_file="$(ls -Ap | grep -v /$ 2> /dev/null)" 
        shasum -a 256 ${_list_file:-./} 2> /dev/null | shasum -a 256 
    } 
fi 

function setup () { 
    build_flag=0 
    dir_index=0 
    max_depth=0 
    depth=0 
} 

function unset_depth () { 
    for ((depth=${max_depth}; depth>0; depth--)); do 
        unset array2_${depth} 
    done 
} 

function watch () { 
    cd "$1" 
    if [ $((++depth)) -gt ${max_depth} ]; then 
        max_depth=${depth} 
        input_array2 "index" "${depth}" "0" 
    fi 
    local _build_flag=${build_flag} 
    for _sub_dirname in $(ls -Ap | grep /$); do 
        watch "${_sub_dirname}" 
    done 
    local _hash="$(update)" 
    ((dir_index++)) 
    if [ "${_hash}" != "${buffer[${dir_index}]}" ] || [ ${run_number} -eq 1 ]; then 
        buffer[${dir_index}]="${_hash}" 
        ((build_flag++)) 
    fi 
    if [ ${_build_flag} -ne ${build_flag} ]; then 
        input_array2 "${depth}" "$((array2_index["${depth}"]++))" "$(pwd)" 
    fi 
    ((depth--)) 
    cd ../ 
} 

function build () { 
    . "${PROJECT_DIR}/processing.sh" 
    BUILD_DIR="${BRANCH_DIR}/$(bash -c 'echo ${PPID}')" 
    mkdir -p "${BUILD_DIR}" 
    cp -R "${CACHE_DIR}/${TARGET_DIRNAME}" "${BUILD_DIR}" 2> /dev/null || cp -R "${TARGET_DIR}" "${BUILD_DIR}" 
    for ((depth=${max_depth}; depth>0; depth--)); do 
        local _max_index="$(max_array2 ${depth})" 
        for ((index=0; index<${_max_index}; index++)); do 
            processing & 
        done 
        # 全部の処理が終わるまで上位の処理に移らないから，同じ重さの処理は深さを揃えた方がいい 
        wait 
    done 
    rm -rf "${CACHE_DIR}" 
    mv "${BUILD_DIR}" "${CACHE_DIR}/" 
    echo "${BRANCH_DIR}" 
    echo "Run number ${run_number} finished" 
    exit 
} 

# 空白を含む名前を扱う 
ORI_IFS=${IFS} IFS=$'\n' 
run_number=1 

while true; do 
    setup 
    watch "${TARGET_DIR}" 
    if [ ${dir_index} -ne ${max_dir_index:=${dir_index}} ]; then 
        max_dir_index=${dir_index} 
        unset buffer 
        unset_depth 
        build_flag=0 
    fi 
    if [ 0 -ne ${build_flag:=0} ]; then 
        build & 
        ((run_number++)) 
        unset_depth 
    fi 
    sleep ${INTERVAL} 
done 