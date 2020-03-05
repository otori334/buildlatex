#!/bin/bash 

for filename in * 
do 
  sed -i '' -e "s/\\label{}/\\label{${filename%.*}}/g" ${filename} 
done 
