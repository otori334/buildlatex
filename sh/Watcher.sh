#!/bin/sh

PROJECT_DIR=$(cd $(dirname $0); cd ../; pwd)
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)

md="${PROJECT_DIR}/src/md/0000_title.md"

# Thanks to https://qiita.com/tamanobi/items/74b62e25506af394eae5
update() {
  echo `openssl sha256 -r $1 | awk '{print $1}'`
}

# Thanks to https://qiita.com/miminashi/items/cf6ef3fd63c12b5fec67
arraynum() #1以上の整数に整形
{
  echo $1 | cut -d"_" -f1 | sed 's/0*\([0-9]*[0-9]$\)/\1/g' | echo `expr $(cat) + 1`
}

INTERVAL=1 #監視間隔, 秒で指定
no=0
cd ${PROJECT_DIR}/src/md
  
for f in *.md
  do
    b=`arraynum ${f}`
    last[${b}]=`update ${f}`
    echo last_sha256_"${b}","${last[${b}]}"
  done
  echo "o\to\to\to\to\t\n"
  
while true; do
                while true; do
                  sleep $INTERVAL
                  for f in *.md
                    do
                      b=`arraynum ${f}`
                      current[${b}]=`update ${f}`
                      if [ "${current[${b}]}" != "${last[${b}]}" ] ; then
                        c=`expr ${b} - 1`.md
                        break 2
                      fi
                    done
                done                    
                  
                for f in *.md
                  do
                    b=`arraynum ${f}`
                    last[$b]="${current[${b}]}"
                    echo last_sha256_"${b}","${last[${b}]}"
                  done
                #eval  ${PROJECT_DIR}/sh/build.sh　aaaaaaaa
                nowdate=`date '+%Y/%m/%d'`
                nowtime=`date '+%H:%M:%S'`
                no=`expr $no + 1`
                ${PROJECT_DIR}/sh/build.sh $no $nowdate $nowtime $c&
                #${PROJECT_DIR}/sh/test.sh $no $nowdate $nowtime $c&
                echo "updated\nno:$no\ndate:$nowdate\ntime:$nowtime\nfile:$c\n"
                echo "o\to\to\to\to\t\n"
done