#!/bin/bash 

current_dir="$(pwd)" && cd "${BUILD_DIR:=ERROR}${relative_path:=ERROR}" || exit 1 
rm -f *.{md,bib} 
cp "${PROJECT_DIR}${relative_path}/"*.{md,bib} ./ 2> /dev/null 

# Thanks to https://yanor.net/wiki/?シェルスクリプト/sedでバックスラッシュを置換する際の注意点 
# LaTeX の強制改行 "\\" を Pandoc が "\" のエスケープと判断するのを防ぐ 
sed -i '' \
-e 's/\\\\/\\mymynewline/g' \
-e 's/\\,/\\mymysmallspace/g' \
-e 's/\\begin{comment}/<!--/g' \
-e 's/\\end{comment}/-->/g' *.md 
                      
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
-e 's/begin{figure}/begin{figure}[htb]/g' automatic_generated.tex 

cp automatic_generated.tex "${PROJECT_DIR}/dest/contents.tex" 

cp automatic_generated.tex ../ 
cd "${current_dir}" 