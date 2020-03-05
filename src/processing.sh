#!/bin/bash 

sed -i '' -e 's/\\,/\\mymysmallspace/g' *.md 
sed -i '' -e 's/\\\\/\\mymynewline/g' *.md 
sed -i '' -e 's/\\begin{comment}/<!--/g' *.md 
sed -i '' -e 's/\\end{comment}/-->/g' *.md 

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

mv ./automatic_generated.pdf "${PROJECT_DIR}/dest/report.pdf"

