# using-grops

utf8 を使用する環境の groff で日本語のマンページを ps で出力します。日
本語の ps にイタリックやボールドを追加します。grops は groff の ps ド
ライバです。

確認に FreeBSD を使いました。Linux とはパッケージのインストール方法や
ファイル名、ディレクトリ名が違いますが、基本的には同じだと思います。

## はじめに

日本語のマンページを utf8 環境で扱えるようにします。おすすめは false
at wizard-limit.net さんの [FreeBSDの日本語マニュアル(2)][] です。こち
らを参照してください。

[FreeBSDの日本語マニュアル(2)]: https://qiita.com/false-git@github/items/d1eb2f680801a1a75edb

## 日本語のフォントの追加

Peter Schaffter さんの [Adding fonts to groff][] を参考に日本語のフォ
ントを追加します。例を示します。

```
$ sudo pkg install fontforge ja-font-std
$ sudo install-font.sh MR /usr/local/share/fonts/std.ja_JP/Ryumin-Light
$ sudo install-font.sh GR /usr/local/share/fonts/std.ja_JP/GothicBBB-Medium
```

MR と GR は groff のフォントです。名前はファミリとスタイルを表わします。
M と G がファミリ、R がスタイルです。

[Adding fonts to groff]: http://www.schaffter.ca/mom/momdoc/appendices.html#fonts

## フォントを組み合わせる

groff は、デフォルトで T (Times) を使いますが、このフォントに日本語の
字体はありません。しかし、[Special Fonts][] で日本語の字体を追加できま
す。例を示します。

```
$ cp /usr/local/share/groff/current/tmac/ps.tmac .
$ patch <ps.tmac.patch
$ sudo cp ps.tmac ps.local /usr/local/share/groff/site-tmac
```

字体の追加に fspecial を使います。

```
$ vi ps.local
.fspecial TR MR
.fspecial TI MI
.fspecial TB MB
.fspecial TBI MBI
.fspecial HR GR
.fspecial HI GI
.fspecial HB GB
.fspecial HBI GBI
```

ここにはまだ作成していないフォント MI MB MBI GI GB GBI も使われていま
す。作り方は次の「フォントにスタイルを追加する」で説明します。

[Special Fonts]: https://www.gnu.org/software/groff/manual/html_node/Special-Fonts.html

## フォントにスタイルを追加する

groff の基本のスタイルは R I B BI ですが、日本語のフォントは R のみで、
I B BI は用意されてないものが多いと思います。例は、足りないスタイルを
fontforge で作ります。

```
$ generate-font.sh I Ryumin-Light
$ generate-font.sh B Ryumin-Light
$ generate-font.sh BI Ryumin-Light
```

メモリ 1GB の VM でゴシックも作成しておよそ30分です。
インストールは次のとおりです。

```
$ sudo install-font.sh MI IPAMincho-Italic.ttf
$ sudo install-font.sh MB IPAMincho-Bold.ttf
$ sudo install-font.sh MBI IPAMincho-BoldItalic.ttf
```

generate-font.sh は、与えられたフォントを指定のスタイル (I B BI) に変
形します。出力されるファイル名は、ps の fontname + .ttf です。途中でエ
ラーメッセージが出力されていますが、フォントは作られているようです。


## 日本語の ps を出力する

次の例は、日本語のマンページ (euc-jp) を ps で出力します。

```
$ GROFF=/usr/local/bin/groff
$ zcat `man -w コマンド名` | $GROFF -S -man -dlocale=ja.UTF-8 -KEUC-JP -t > a.ps
```

man コマンドは、中でページや利用者のロケールから判定して、、、と思って
はいますが、まとまっておりません。


## お好みで

### 行間の補正

日本語のフォントは欧文のものより高さがあり、行間を広げると読みやすくな
ります。次の例は、行間を調整する man マクロと mdoc マクロの断片です。
日本語を扱うところに加えます。想像できると思いますが、欧文やコードが続
くところは間延びするので、広げすぎもいけません。お好みでどうぞ。

```
$ sudo cp line-gap.patch /usr/local/share/groff/site-tmac
$ cd /usr/local/share/groff/site-tmac
$ sudo patch <line-gap.patch
```

以下は、line-gap.patch の内容です。


* man マクロの行間を補正する

```
$ vi man_ja.local
.am1 TH
.  if t \{\
.      nr VS +(\\n[VS]u * 50 / 100)
.      ps \\n[PS]u
.      vs \\n[VS]u
.      ll \\n[LL]u
.  \}
..
```

* mdoc マクロの行間を補正する

```
$ vi mdoc_ja.local
.if t .vs +(\n[.v]u * 50 / 100)
```

### 行末揃え

日本語のマンページは行末揃えを抑止するものとそうでないものがあります。
ハイフネーションも同様です。troff (ps 出力) は nroff (ターミナル出力)
より、1行の文字数が多いこともあって、行末を揃えても見苦しくありません。

たとえば n (nroff ターミナルへの出力) ではいままでどおり行揃えを抑止し、
それ以外は行末揃えを試すなら、行揃えを抑止する `.na` の前に `.if n` の
条件を付けます。ハイフネーションも同様です。

ここでは行末揃えが働きやすくするためにテンやマルの字体に含まれるアキを
空白に変え、フォントも等幅でなくプロポーショナルフォントをインストール
し、サンプルを grops-pp.pl というスクリプトにまとめました。grops の
DESC ファイルに prepro 行として追加して使います。

```
GROFF_DEVPS_DIR=/usr/local/share/groff/current/font/devps
cp DEVPS_DIR/devps/DESC .
echo prepro grops-pp.pl >> DESC
install -m 644 DESC $GROFF_DEVPS_DIR
```

grops-pp.pl は単純な置換をしています。好みは人それぞれだと思います。

誤りや改善のご指摘がありましたら、お気軽にどうぞ。
