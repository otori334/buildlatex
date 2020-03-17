# double_buffer

## ファイル変更の保存をトリガーに build.sh を実行する監視スクリプト watcher.sh について  

buffer を一つに減らした．なぜならばファイルを監視用途ではハッシュの変更を捉えたあと特別な処理をしないので 

[自作したゲームコントローラのファームウェア](https://ecml.jp/archives/545) は buffer を二つ備え，過去と現在二つの状態を記録した．watcher.sh はこれを元に書いた．
