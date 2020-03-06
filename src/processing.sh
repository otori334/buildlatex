#!/bin/bash 

pandoc ./*.md -N -o ./automatic_generated.tex \
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
sed -i '' -e 's/\\mymysmallspace/\\,/g' automatic_generated.tex 
sed -i '' -e 's/\\mymynewline/\\\\/g' automatic_generated.tex 
sed -i '' -e 's/\\cite\\{/~\\cite/g' automatic_generated.tex 
sed -i '' -e 's/null//g' automatic_generated.tex 
sed -i '' -e 's/。/．/g' automatic_generated.tex 
sed -i '' -e 's/、/，/g' automatic_generated.tex 
sed -i '' -e 's/\\%/%/g' automatic_generated.tex 
sed -i '' -e 's/includegraphics/includegraphics[width=1.0\\columnwidth]/g'  automatic_generated.tex 
sed -i -e 's/begin{figure}/begin{figure}[htb]/g' automatic_generated.tex 

find . -name "*.tex-e" -exec rm {} \; 


cp ./automatic_generated.tex "${PROJECT_DIR}/dest/contents.tex"

latexmk
mv ${BUILD_DIR}/automatic_generated.pdf ${PROJECT_DIR}/dest/output.pdf 
