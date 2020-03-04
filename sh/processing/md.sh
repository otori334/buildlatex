#!/bin/bash 

function processing () { 
  index=0 
  until [ $index -eq 10 ]; do 
    index=$(( index + 1 )) 
    echo $index 
  done 
  exit 
  # https://linuxcommand.net/read/#read-2 
  # whileと組み合わせてファイルから行を読み込む 
  return 0 
} 