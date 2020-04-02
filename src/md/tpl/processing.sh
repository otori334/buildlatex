#!/bin/bash 

current_dir="$(pwd)" && cd "${BUILD_DIR:=ERROR}${relative_path:=ERROR}" || exit 1 
cp "${PROJECT_DIR}${relative_path}/"{*,.*} ../ 2> /dev/null 
cd "${current_dir}" 