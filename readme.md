# これは何 

- プログラムのビルド作業を自動化するツール 
- Markdown -> LaTeX -> pdf をやるサンプルコード付き 

```
$ ./sh/watcher.sh 
```

## ビルドツールとしての特徴 

- ファイル変更の保存をトリガに自動でコンパイルを実行する 
- 依存関係をディレクトリ構成で表現し，簡単に記述できる 
- 実行する処理はディレクトリ名・深さから指定する 
- 変更があったディレクトリを起点に，上位のディレクトリに向かって再帰的にコンパイルする 
- 依存関係がない処理を並列実行して高速化する 
- 中間生成ファイルをキャッシュして高速化する 
- プロジェクトディレクトリが中間生成ファイルまみれになるのを防ぐ 

## 組版ツールとしての特徴 

- LaTeX のデバッグをせずに済む 
  - Pandoc の解釈を通してエラーを減らす 
  - 変更を保存するたびにエラーチェックする 
  - エラー通知までターミナルを見なくて済む 
  - LaTeX のひどいエラーメッセージを読まなくて済む 

## 組版の参考 

- LaTeX
  - [ぼくのそつろんしっぴつかんきょう](http://mtjune.hateblo.jp/entry/2015/12/10/144657) 
  - [卒論をLaTeXで書くためのエッセンス](https://github.com/tinoji/sotsuron_wo_LaTeX_de) 
  - [アカデミックヤクザにキレられないためのLaTeX論文執筆メソッド](https://qiita.com/suigin/items/10960e516f2d44f6b6de) 
- Pandoc 
  - [Pandoc ユーザーズガイド 日本語版](http://sky-y.github.io/site-pandoc-jp/users-guide/) 
  - [学位論文を書く準備](https://blog.8tak4.com/post/168232661994/know-how-writing-thesis-markdown) 
  - [LaTeXのレポート作成で消耗しない為に](https://hackmd.io/@w1rIom6MSiqiVrxJLM2zDA/H1kwLqvZG?type=view) 
  - [大学のレポートをMARKDOWNで爆速で書く話](https://beanlog.xyz/blog/write-report-use-markdown/) 
  - [MacでPandocを使ってマークダウンをPDFに変換](https://www.yamamanx.com/mac-pandoc-pdf/) 
  - [PandocとPDFのレイアウトの話](https://qiita.com/takada-at/items/c807c163bd861bbec7cf) 
- その他 
  - [Atomでの論文執筆環境を整える](https://tomochemist.com/2019/02/11/post-264/) 
  - [これに勝てるLaTeXエディタを俺は知らない](https://mobile.twitter.com/5ebec/status/1065872335108956161)
  - [textlintで文章をチェックしよう！](https://www.to-r.net/media/textlint/) 

## TODO 

- [ ] [Docker](https://qiita.com/Kumassy/items/ffa752da5f7193c4929c) 
- [ ] [差分](http://abenori.blogspot.com/2016/06/latexdiff.html) 
- [ ] [ディレクトリで章立てを管理](https://qiita.com/sankichi92/items/1e113fcf6cc045eb64f7) 
- [ ] [ディレクトリで章立てを管理](https://qiita.com/sakas1231/items/14c96f99d7507b928938) 

<!--
- ./sh/Shortcuts.alfredworkflow などはおまけだから，自動化ツールとして使うなら不要 


- [ ] make 
  - [ ] [Pandocを使ってMarkdownからLatexによるPDF生成をする](https://qiita.com/kzmssk/items/9607454705b91916f0ff) 
  - [ ] [卒論のtexをmarkdownで書いた話](http://mbuchi.hateblo.jp/entry/2015/03/18/105743) 
  - [ ] ~~processing をディレクトリ名に応じた make に置き換える~~ 
  - [ ] processing をディレクトリ名に応じた make に置き換える 
- [ ] 置換 
  - [ ] Pandoc フィルタ 
  - [ ] [ruby](https://qiita.com/ish_774/items/82cbda064792306a5493) 
  - [x] sed  
    - [x] Pandoc フィルタを使った方がスマートだけど sed が十分機能してる 
- [ ] [git difftool](https://git-scm.com/docs/git-difftool) 
- [x] prefixで管理する 
- [x] watcher.sh と build.sh を統合 
- [x] 勝手に同期されるフォルダの中でブランチ切り替えるとよくないことが起こる 
-->
