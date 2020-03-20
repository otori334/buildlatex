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
- [ ] make 
  - [ ] [Pandocを使ってMarkdownからLatexによるPDF生成をする](https://qiita.com/kzmssk/items/9607454705b91916f0ff) 
  - [ ] [卒論のtexをmarkdownで書いた話](http://mbuchi.hateblo.jp/entry/2015/03/18/105743) 
  - [ ] processing を ディレクトリ名に応じた make に置き換える
- [ ] 置換 
  - [ ] Pandoc フィルタ 
  - [ ] [ruby](https://qiita.com/ish_774/items/82cbda064792306a5493) 
  - [x] シェル 
- [ ] 差分 
  - [ ] [latexdiff](http://abenori.blogspot.com/2016/06/latexdiff.html) 
  - [ ] [git difftool](https://git-scm.com/docs/git-difftool) 
- [x] ~~章立てをディレクトリで分けて管理~~ prefixで管理するのが現実的

<!--
- [x] 勝手に同期されるフォルダの中でブランチ切り替えるとよくないことが起こる 
-->

## 参考

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

