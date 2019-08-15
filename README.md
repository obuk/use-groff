# groff で日本語を処理する

utf8 を使用する環境の groff で日本語の ps を出力します。

はじめに、
日本語のマンページを utf8 環境で扱えるようにします。おすすめは false
at wizard-limit.net さんの [FreeBSDの日本語マニュアル(2)][] です。こち
らを参照してください。

[FreeBSDの日本語マニュアル(2)]: https://qiita.com/false-git@github/items/d1eb2f680801a1a75edb

* ubuntu はこの部分を省略できます。

## PS (grops)

手順は以下のとおりです。(grops は groff の ps ドライバです。)

確認に FreeBSD を使いました。Linux とパッケージのインストール方法や
ファイル名、ディレクトリ名が違いますが、基本的には同じです。

* ubuntu で確認に使用したスクリプトは、eg/setup-grops-ja-ubuntu.sh と
  eg/setup-grops-ja-ubuntu-with-noto.sh です。

### 日本語のフォントの追加

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

* 新しい groff のマンページは、truetype フォントのインストール方法を説
  明しています。

### フォントを組み合わせる

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
.fspecial CR MR
.fspecial CI MI
.fspecial CB MB
.fspecial CBI MBI
.fspecial HR GR
.fspecial HI GI
.fspecial HB GB
.fspecial HBI GBI
```

日本語は斜体を使わないので、MI GI の代りに MR GR を使っても不都合が生
じることはないだろうと思います。

[Special Fonts]: https://www.gnu.org/software/groff/manual/html_node/Special-Fonts.html

### フォントにスタイルを追加する

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
ラーメッセージが出力されますが、フォントは作られると思います。


### 日本語の ps を出力する

次の例は、日本語のマンページ (euc-jp) を ps で出力します。

```
$ GROFF=/usr/local/bin/groff
$ zcat `man -w コマンド名` | $GROFF -S -man -dlocale=ja.UTF-8 -KEUC-JP -t > a.ps
```

man コマンドは、中でページや利用者のロケールから判定して、、、と思って
はいますが、まとまっておりません。


### お好みで

#### 行間の補正

日本語のフォントは欧文のものより高さがあり、行間を広げると読みやすくな
ります。次の例は、行間を調整する man マクロと mdoc マクロの断片です。
日本語を扱うところに加えます。想像できると思いますが、欧文やコードが続
くところは間延びするので、広げすぎもいけません。お好みでどうぞ。

* man マクロの行間を補正する

```
$ vi man.local
.if t \{\
.  if "\*[locale]"japanese" \{\
.am1 TH
.  nr VS (\\n[PS] * 180 / 100)
.  vs \\n[VS]u
..
.  \}
.\}
```

* mdoc マクロの行間を補正する

```
$ vi mdoc.local
.if t \{\
.  if "\*[locale]"japanese" \{\
.    vs (\n[.s]p * 180 / 100)
.  \}
.\}
```

* perl モジュールの pod から出力されるマンページの行間を補正する

```
=begin man

.if t \{\
.  nr VS (\n[PS] * 180 / 100)
.  vs \n[VS]u
.\}
.am Vb
.if t \{\
.  nr VS_BAK \\n[VS]
.  nr VS (\\n[PS] * 120 / 100)
.  vs \\n[VS]u
.\}
..
.am Ve
.if t \{\
.  nr VS \\n[VS_BAK]
.  vs \\n[VS]u
.\}
..

=end man
```

#### 行末揃え

日本語のマンページには行末揃えやハイフネーションを抑止しているものとそ
うでないものがあります。試しに使う方法を示します。

1. 行末揃えやハイフネーションを許します。（nroff はいままでどおり）

```
.if n .na
.if n .hy 0
```

2. 日本語の行末揃えのために句読点や括弧類の前後と文字間に伸縮可能なス
   ペースを加えます。（詳細は [sample.7](sample.7) を参照）

```
GROFF_DEVPS_DIR=/usr/local/share/groff/current/font/devps
sudo apt-get -y install libyaml-syck-perl
sudo install pre-grops.pl /usr/local/bin/
sudo install pre-grops.rc /etc/groff/
(sed /^prepro/d $GROFF_DEVPS_DIR/DESC; echo prepro pre-grops.pl) >DESC
sudo install -m 644 DESC $GROFF_DEVPS_DIR
```

## PDF (gropdf)

修正は [gropdf.patch](gropdf.patch) にあります。

処理時間やファイルサイズを比べると、
groff で ps を出力し、gs で pdf に変換する方が良いかもしれません。

修正内容は下記のとおりです。

### Too many glyphs used

groff で pdf を出力すると次のメッセージが出力されます。

```
Too many glyphs used in font 'n'
```

gropdf(1) に次のとおり説明されています。(groff 1.22.4)

Note that gropdf is currently only able to display the first 256
glyphs in any font.  This restriction will be lifted in a later
version.

修正は、使用字体が256を越える度に辞書を増やすというもので、
詳細はパッチを確認してください。

### pdfmark

日本語のしおりを出力するために、ドライバの中で groff の unicode 文字
\\[uXXXX] を UTF-16 にエンコードします。

マクロの修正もありますが、[pdf.tmac.patch](pdf.tmac.patch) のとおり、
ひどいものです。詳しい方に助けて頂きたいと思っています。

groff が出力する pdf のサイズを小さくするために、それから、firefox で
表示するために gs を通す例を示します。オプションの -dPrinted=false を
忘れるとハイパーリンクが働きません。注意してください。

```
/usr/local/bin/groff -Tpdf -Dutf8 -pt -mja -ms -mspdf sample.ms \\
| gs -sDEVICE=pdfwrite -dPrinted=false -dNOPAUSE -dQUIET -dBATCH \\
  -sOutputFile=- - >a.pdf
```

誤りや改善のご指摘がありましたら、お気軽にどうぞ。
