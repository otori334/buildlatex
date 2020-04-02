#!/bin/bash 

current_dir="$(pwd)" && cd "${BUILD_DIR:=ERROR}${relative_path:=ERROR}" || exit 1 
rm -f ../*.{png,jpg,pdf} 
cp "${PROJECT_DIR}${relative_path}/"*.{png,jpg,pdf} ../ 2> /dev/null 
cd "${current_dir}" 