#!/bin/zsh

## sh エミュレーションモード
##https://fumiyas.github.io/2013/12/03/zsh-scripting.sh-advent-calendar.html
##emulate -R sh

set -eu

PROJECT_DIR=$(cd $(dirname $0); cd ../; pwd)
cd ${PROJECT_DIR}

if test $(find ./ -name "*.tex" | wc -l) -gt $(find ./ -name "*.md" | wc -l) ; then
  sed -i '' -e 's/\\begin{comment}/<!--/g' *.tex
  sed -i '' -e 's/\\end{comment}/-->/g' *.tex
  for f in *.tex
  do
    mv $f ${f%.*}.md
  done
else
  sed -i '' -e 's/<!--/\\begin{comment}/g' *.md
  sed -i '' -e 's/-->/\\end{comment}/g' *.md
  for f in *.md
  do
    mv $f ${f%.*}.tex
  done
fi
