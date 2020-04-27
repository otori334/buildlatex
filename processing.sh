#!/bin/bash 

function processing () { 
    cd "${BUILD_DIR:-/NO_BUILD_DIR}" || exit 1 
    # 危ない-> "rm -f *.tex ../*.tex" カレントディレクトリで実行しないように注意 
    processing_dir="$(output_array2 ${depth} ${index})" 
    processing_dirname="$(echo "${processing_dir}" | sed -e 's/.*\/\([^\/]*\)$/\1/')" 
    cd "${exist_test_dir:=${processing_dir/${PROJECT_DIR}/${BUILD_DIR}}}" 2> /dev/null || { 
        cp -R "${processing_dir}" "${exist_test_dir%/*}"; 
        cd "${exist_test_dir}"; 
    } 
    
    case "${processing_dirname}" in 
        "eq") 
            mv "../automatic_generated.tex" "../automatic_generated.tex-bak" 2> /dev/null 
            rm -f *.tex ../*.tex 
            mv "../automatic_generated.tex-bak" "../automatic_generated.tex" 2> /dev/null 
            cp "${processing_dir}/"*.tex ./ # 2> /dev/null 
            for _filename in *.tex 
            do 
                sed -i '' -e "s/\label{}/\label{${_filename%.*}}/g" "${_filename}" 
            done 
            cp *.tex ../ # 2> /dev/null 
            exit 
        ;; 
        "fig") 
            rm -f ../*.{png,jpg,pdf} 
            cp "${processing_dir}/"*.{png,jpg,pdf} ../ 2> /dev/null 
            exit 
        ;; 
        "md") 
            rm -f *.{md,bib} 
            cp "${processing_dir}/"*.{md,bib} ./ 2> /dev/null 
            # Thanks to https://yanor.net/wiki/?シェルスクリプト/sedでバックスラッシュを置換する際の注意点 
            # LaTeX の強制改行 "\\" を Pandoc が "\" のエスケープと判断するのを防ぐ 
            sed -i '' \
            -e 's/\\\\/\\mymynewline/g' \
            -e 's/\\,/\\mymysmallspace/g' \
            -e 's/\\begin{comment}/<!--/g' \
            -e 's/\\end{comment}/-->/g' \
            *.md 
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
            -e 's/begin{figure}/begin{figure}[htb]/g' \
            automatic_generated.tex 
            # -e 's/\\textbf{/\\textcolor{yellow}{/g' \
            cp automatic_generated.tex "${PROJECT_DIR}/dest/contents.tex" 
            cp automatic_generated.tex ../ 
            exit 
        ;; 
        "tpl" ) 
            cp "${processing_dir}/"{*,.*} ../ 2> /dev/null 
            exit 
        ;; 
        * ) 
            case "${depth}" in 
                1 ) 
                    rm -f automatic_generated.pdf 
                    latexmk || { 
                        echo "error state $?"; 
                        osascript -e 'display notification "something went wrong" with title "latexmk"'; 
                    } 
                    cp automatic_generated.pdf "${PROJECT_DIR}/dest/${TARGET_DIRNAME}.pdf" 2> /dev/null 
                    if [ ${run_number} -eq 1 ]; then 
                        echo "open Skim" 
                        open -a Skim "${PROJECT_DIR}/dest/${TARGET_DIRNAME}.pdf" 
                    fi 
                    # osascript -e 'display notification "processing md->pdf" with title "exit"' 
                    exit 
                ;; 
                * ) 
                    echo "Nonexistent processing_dir ${processing_dir}" 
                    exit 
                ;; 
            esac 
    esac 
} 