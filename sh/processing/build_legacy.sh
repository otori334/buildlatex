#!/bin/zsh

## sh エミュレーションモード
##https://fumiyas.github.io/2013/12/03/zsh-scripting.sh-advent-calendar.html
##emulate -R sh

##osascript -e 'display notification "pandoc->latexmk" with title "processing"'

set -eu

PROJECT_DIR=$(cd $(dirname $0); cd ../; pwd)
cd ${PROJECT_DIR}
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)

BUILD_DIR="/tmp/buildlatex-${CURRENT_BRANCH}"
mkdir -p "${BUILD_DIR}"
cd ${BUILD_DIR}
find . -name "*.md" -exec rm {} \;
#find . -name "*.pdf" -exec rm {} \;
cp -R ${PROJECT_DIR}/src ${BUILD_DIR}/

if [ -e "${BUILD_DIR}/src/edit" ]; then
  echo "edit directory exists"
  cd ${BUILD_DIR}/src/edit
  if test $(find ./ -name "*.md" | wc -l) -ne 0 ; then
    echo "edit file *.md exists"
    for f in *.md
    do
      mv $f ${BUILD_DIR}/src/
    done
    mv references.bib ${BUILD_DIR}/src/
  else
    echo "edit file *.md not exists"
  fi
  cd ${BUILD_DIR}/src
  rm -rf "${BUILD_DIR}/src/edit"
else
  echo "edit directory not exists"
fi

if [ -e "${BUILD_DIR}/src/equation" ]; then
  echo "equation directory exists"
  cd ${BUILD_DIR}/src/equation
  if test $(find ./ -name "*.tex" | wc -l) -ne 0 ; then
    echo "equation file *.tex exists"
    for f in *
    do
      sed -i '' -e "s/\\label{}/\\label{${f%.*}}/g" $f
    done
    mv ${BUILD_DIR}/src/equation/* ${BUILD_DIR}/src
  else
    echo "equation file *.tex not exists"
  fi
  cd ${BUILD_DIR}/src
  rm -rf "${BUILD_DIR}/src/equation"
else
  echo "equation directory not exists"
fi

if [ -e "${BUILD_DIR}/src/template" ]; then
  echo "template directory exists"
  cd ${BUILD_DIR}/src/template
  if test $(ls -F | grep -v / | wc -l) -ne 0 ; then
    echo "template file * exists"
    mv ${BUILD_DIR}/src/template/* ${BUILD_DIR}/src
  else
    echo "template file * not exists"
  fi
  cd ${BUILD_DIR}/src
  rm -rf "${BUILD_DIR}/src/template"
else
  echo "template directory not exists"
fi

if [ -e "${BUILD_DIR}/src/img" ]; then
  echo "img directory exists"
  cd ${BUILD_DIR}/src/img
  if test $(ls -F | grep -v / | wc -l) -ne 0 ; then
    echo "img file * exists"
    mv ${BUILD_DIR}/src/img/* ${BUILD_DIR}/src
  else
    echo "img file * not exists"
  fi
  cd ${BUILD_DIR}/src
  rm -rf "${BUILD_DIR}/src/img"
else
  echo "img directory not exists"
fi

if [ -e "${BUILD_DIR}/src/last" ]; then
  echo "last directory exists"
  cd ${BUILD_DIR}/src/last
  if test $(ls -F | grep -v / | wc -l) -ne 0 ; then
    echo "last file * exists"
    mv ${BUILD_DIR}/src/last/* ${BUILD_DIR}/src
  else
    echo "last file * not exists"
  fi
  cd ${BUILD_DIR}/src
  rm -rf "${BUILD_DIR}/src/last"
else
  echo "last directory not exists"
fi

if test $(find ./ -name "*.md" | wc -l) -ne 0 ; then  
  echo "file *.md exists in src directory"
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
  -M "crossrefYaml=${BUILD_DIR}/src/config.yml"
  
  sed -i '' -e 's/\\mymysmallspace/\\,/g' automatic_generated.tex
  sed -i '' -e 's/\\mymynewline/\\\\/g' automatic_generated.tex
  sed -i '' -e 's/\\cite\\{/~\\cite/g' automatic_generated.tex
  sed -i '' -e 's/null//g' automatic_generated.tex
  sed -i '' -e 's/。/．/g' automatic_generated.tex
  sed -i '' -e 's/、/，/g' automatic_generated.tex
  sed -i '' -e 's/\\%/%/g' automatic_generated.tex
  sed -i '' -e 's/includegraphics/includegraphics[width=1.0\\columnwidth]/g' automatic_generated.tex
  sed -i -e 's/begin{figure}/begin{figure}[htb]/g' automatic_generated.tex
  
  find . -name "*.tex-e" -exec rm {} \;
else
  echo "file *.md not exists in src directory"
fi

cp ./automatic_generated.tex "${PROJECT_DIR}/dest/contents.tex"

latexmk

mv ./automatic_generated.pdf "${PROJECT_DIR}/dest/report.pdf"

osascript -e 'display notification "exit md->pdf" with title "processing"'

open -a Skim ${PROJECT_DIR}/dest/report.pdf