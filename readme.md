# buildlatex

ラッピングして使ってきた組版のいろいろを整理

## ビルド

```bash
$ ./sh/build.sh
```

## 監視

```bash
$ ./sh/watcher.sh eq
```

第一引数で監視するディレクトリを指定します． src 直下にあるディレクトリから選べます．指定しない場合は　md をデフォルトで監視します．指定したディレクトリ直下のファイルに変更があるとビルドします．

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
  - [【CLI・atom対応】textlintで文章をチェックしよう！](https://www.to-r.net/media/textlint/) 

## 今後改善したい点 

- [ ] 章立てをディレクトリで分けて管理する 
- [ ] LaTeXdiff 
  - [ ] gitdiff 
- [ ] Docker 
  - [ ] [まだまだ Word で消耗してるの？ 大学のレポートを Markdown で書こう （Docker 編](https://qiita.com/Kumassy/items/ffa752da5f7193c4929c) 
- [ ] rubyで置換 
  - [ ] [Markdown+Texの環境構築と使い方](https://qiita.com/ish_774/items/82cbda064792306a5493) 
- [ ] make
  - [ ] [Pandocを使ってMarkdownからLatexによるPDF生成をする](https://qiita.com/kzmssk/items/9607454705b91916f0ff) 
  - [ ] [卒論のtexをmarkdownで書いた話](http://mbuchi.hateblo.jp/entry/2015/03/18/105743) 

  <!--
- [x] 勝手に同期されるフォルダの中でブランチ切り替えるとよくないことが起こる 
-->

