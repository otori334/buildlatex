# buildlatex

ラッピングして使ってきた組版のいろいろを整理

## build

Markdown -> LaTeX -> pdf をやる

```bash
$ ./sh/build.sh 
```

## watcher

ファイル変更の保存をトリガーに build.sh を実行する監視スクリプト

```bash
$ ./sh/watcher.sh eq 
```

- 第一引数で監視対象を指定
- src 直下から選ぶ（ デフォルトは md ）

## 思い出しポイント

- [ ] Docker 
  - [ ] [まだまだ Word で消耗してるの？ 大学のレポートを Markdown で書こう（Docker 編）](https://qiita.com/Kumassy/items/ffa752da5f7193c4929c) 
- [ ] rubyで置換 
  - [ ] [Markdown+Texの環境構築と使い方](https://qiita.com/ish_774/items/82cbda064792306a5493) 
- [ ] make 
  - [ ] [Pandocを使ってMarkdownからLatexによるPDF生成をする](https://qiita.com/kzmssk/items/9607454705b91916f0ff) 
  - [ ] [卒論のtexをmarkdownで書いた話](http://mbuchi.hateblo.jp/entry/2015/03/18/105743) 
- [ ] フィルタ実装 
- [ ] 差分 
  - [ ] LaTeXdiff 
  - [ ] gitdiff 
- [ ] 章立てをディレクトリで分けて管理 

<!--
- [x] 勝手に同期されるフォルダの中でブランチ切り替えるとよくないことが起こる 
-->

## 参考

- シェルスクリプト
  - [ぼくのそつろんしっぴつかんきょう](http://mtjune.hateblo.jp/entry/2015/12/10/144657) 
  - [学位論文を書く準備](https://blog.8tak4.com/post/168232661994/know-how-writing-thesis-markdown) 
  - [卒論・修論をLaTeXで書くためのチェック項目16](https://www.ketsuago.com/entry/2016/01/30/191934) 
- 環境構築 
  - [LaTeXのレポート作成で消耗しない為に](https://hackmd.io/@w1rIom6MSiqiVrxJLM2zDA/H1kwLqvZG?type=view) 
  - [大学のレポートをMARKDOWNで爆速で書く話](https://beanlog.xyz/blog/write-report-use-markdown/) 
  - [MacでPandocを使ってマークダウンをPDFに変換](https://www.yamamanx.com/mac-pandoc-pdf/) 
  - [Pandoc ユーザーズガイド 日本語版](http://sky-y.github.io/site-pandoc-jp/users-guide/) 
  - [PandocとPDFのレイアウトの話](https://qiita.com/takada-at/items/c807c163bd861bbec7cf) 
  - [Atomでの論文執筆環境を整える](https://tomochemist.com/2019/02/11/post-264/) 
  - [textlintで文章をチェックしよう！](https://www.to-r.net/media/textlint/) 

