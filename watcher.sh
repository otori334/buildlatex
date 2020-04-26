#!/bin/bash 

# 監視間隔を秒で指定 
readonly INTERVAL=1 
readonly TMP_DIR="/tmp" 
readonly CACHE_DIRNAME="cache" 
readonly TARGET_DIRNAME="${@:-src}" 
readonly PROJECT_DIR="$(cd "$(dirname "$0")"; pwd)" 
readonly PROJECT_DIRNAME="$(echo "${PROJECT_DIR}" | sed -e 's/.*\/\([^\/]*\)$/\1/')" 
readonly GIT_BRANCHNAME="$(cd "${PROJECT_DIR}"; git rev-parse --abbrev-ref HEAD)" 
readonly BRANCH_DIR="${TMP_DIR}/${PROJECT_DIRNAME}_${GIT_BRANCHNAME}_${TARGET_DIRNAME}" 
readonly CACHE_DIR="${BRANCH_DIR}/${CACHE_DIRNAME}" 
trap 'echo "end watcher.sh" && rm -rf "${BUILD_DIR}" && exit' 0 1 2 3 15 
cd "${PROJECT_DIR}/${TARGET_DIRNAME}" || exit 1 
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
    function update () { 
        # ls はタイムスタンプの粒度が秒だから，1秒以下の変化を捉えるのには力不足 
        # 監視対象が膨大な場合に有効 
        ls -l | shasum -a 256 
    } 
else 
    function update () { 
        local _list_file="$(ls -Ap | grep -v /$ 2> /dev/null)" 
        # ファイル数が多いほど遅延が大きくなる 
        # 通常，遅延はミリ秒オーダーだから気にしなくてよい 
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

function glance () { 
    cd "$1" 
    if [ $((++depth)) -gt ${max_depth} ]; then 
        max_depth=${depth} 
        input_array2 "index" "${depth}" "0" 
    fi 
    local _PRE_IFS=${IFS} 
    IFS=$'\n' 
    for _sub_dirname in $(ls -Ap | grep /$); do 
        glance "${_sub_dirname}" 
    done 
    IFS=${_PRE_IFS} 
    input_array2 "${depth}" "$(output_array2 "index" ${depth} )" "$(pwd)" 
    input_array2 "index" "${depth}" $(($(output_array2 "index" ${depth})+1)) 
    ((depth--)) 
    cd ../ 
} 

function watch () { 
    cd "$1" 
    if [ $((++depth)) -gt ${max_depth} ]; then 
        max_depth=${depth} 
        input_array2 "index" "${depth}" "0" 
    fi 
    local _build_flag=${build_flag} 
    local _PRE_IFS=${IFS} 
    IFS=$'\n' 
    for _sub_dirname in $(ls -Ap | grep /$); do 
        watch "${_sub_dirname}" 
    done 
    local _hash="$(update)" 
    IFS=${_PRE_IFS} 
    ((dir_index++)) 
    if [ "${_hash}" != "${buffer[${dir_index}]:=${_hash}}" ]; then 
        buffer[${dir_index}]="${_hash}" 
        ((build_flag++)) 
    fi 
    if [ ${_build_flag} -ne ${build_flag} ]; then 
        input_array2 "${depth}" "$(output_array2 "index" ${depth} )" "$(pwd)" 
        input_array2 "index" "${depth}" $(($(output_array2 "index" ${depth})+1)) 
    fi 
    ((depth--)) 
    cd ../ 
} 

function build () { 
    . "${PROJECT_DIR}/processing.sh" 
    local _build_pid=$(bash -c 'echo ${PPID}') 
    BUILD_DIR="${BRANCH_DIR}/${_build_pid}" 
    mkdir -p "${BUILD_DIR}" 
    cp -R "${CACHE_DIR}/${TARGET_DIRNAME}" "${BUILD_DIR}/" 2> /dev/null || cp -R "${PROJECT_DIR}/${TARGET_DIRNAME}" "${BUILD_DIR}/" 
    for ((depth=${max_depth}; depth>0; depth--)); do 
        local _max_index=$(max_array2 ${depth}) 
        for ((index=0; index<${_max_index}; index++)); do 
            processing & 
        done 
        # 全部の処理が終わるまで上位の処理に移らないから，同じ重さの処理は深さを揃えた方がいい 
        wait 
    done 
    rm -rf "${CACHE_DIR}" 
    mv "${BUILD_DIR}" "${CACHE_DIR}/" 
    echo "Run number ${run_number} finished" 
    exit 
} 

setup 
glance "${PROJECT_DIR}/${TARGET_DIRNAME}" 
run_number=1 
build_flag=1 

while true; do 
    if [ 0 -ne ${build_flag:=0} ]; then 
        build & 
        ((run_number++)) 
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