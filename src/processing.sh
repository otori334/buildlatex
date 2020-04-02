#!/bin/bash 

current_dir="$(pwd)" && cd "${BUILD_DIR:=ERROR}${relative_path:=ERROR}" || exit 1 
latexmk || osascript -e 'display notification "failure" with title "error"' 

cp automatic_generated.pdf "${PROJECT_DIR}/dest/output.pdf" 2> /dev/null && { 
  if [ ${no} -eq 0 ]; then 
    echo "open Skim" 
    open -a Skim "${PROJECT_DIR}/dest/output.pdf" 
  fi 
  # osascript -e 'display notification "processing md->pdf" with title "exit"' 
} 
cd "${current_dir}" 