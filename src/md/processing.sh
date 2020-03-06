#!/bin/bash 

# Thanks to https://yanor.net/wiki/?シェルスクリプト/sedでバックスラッシュを置換する際の注意点
# LaTeX の強制改行 "\\" を Pandoc が "\" のエスケープと判断するのを防ぐ 
sed -i '' -e 's/\\,/\\mymysmallspace/g' *.md 
sed -i '' -e 's/\\\\/\\mymynewline/g' *.md 
sed -i '' -e 's/\\begin{comment}/<!--/g' *.md 
sed -i '' -e 's/\\end{comment}/-->/g' *.md 
