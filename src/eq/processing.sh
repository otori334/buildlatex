#!/bin/bash 

current_dir="$(pwd)" && cd "${BUILD_DIR:=ERROR}${relative_path:=ERROR}" || exit 1 
mv "../automatic_generated.tex" "../automatic_generated.tex-bak" 2> /dev/null 
rm -f *.tex ../*.tex 
mv "../automatic_generated.tex-bak" "../automatic_generated.tex" 2> /dev/null 
cp "${PROJECT_DIR}${relative_path}/"*.tex ./ # 2> /dev/null 
for filename in *.tex; do 
  sed -i '' -e "s/\\label{}/\\label{${filename%.*}}/g" "${filename}" 
done 
cp *.tex ../ # 2> /dev/null 
cd "${current_dir}" 