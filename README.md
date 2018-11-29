# using-grops

最近の groff (ports の groff) で ps を出力します。

FreeBSD で日本語マニュアルを、euc-jp より utf8 で使いたい人向けですが、
Linux でも同様かもしれません。

はじめに
[FreeBSDの日本語マニュアル(2)](https://qiita.com/false-git@github/items/d1eb2f680801a1a75edb)
のとおりに作業して、日本語マニュアルが utf8 で扱えるようにします。

## fontforge と日本語のフォント ja-font-std を用意する

```
$ sudo pkg install fontforge ja-font-std
```

fontforge は依存が多いので気になるかもしれませんが、作業後削除できます。
あるいは他所で作ってもってきてもいいと思います。

## groff (grops) のフォントを作る

詳しい説明は http://www.schaffter.ca/mom/momdoc/appendices.html にあります。

1. ja-font-std の *.gs7 の名前を IPAMincho.ttf と IPAGothic.ttf にします。

```
$ ln -s /usr/local/share/fonts/std.ja_JP/Ryumin-Light.gs7 IPAMincho.ttf
$ ln -s /usr/local/share/fonts/std.ja_JP/GothicBBB-Medium.gs7 IPAGothic.ttf
```

2. fontforge のスクリプトで ttf から afm と t42 を作ります。

```
$ cat > vi generate.pe <<EOF
Open(\$1);
Generate(\$fontname + ".afm");
Generate(\$fontname + ".t42");
EOF
$ fontforge -script generate.pe IPAMincho.ttf
```

3. groff (grops) のフォントを作ります。

```
$ perl `which afmtodit` -s -i0 -m IPAMincho.afm textmap MR
```

4. download ファイルを作ります。

```
$ echo IPAMincho IPAMincho.t42 >download
```

5. ファイルを groff の site-fonts にコピーします。

```
$ sudo mkdir -p $GROFF_SITE_FONT/devps
$ sudo install -m 644 MR IPAMincho.t42 download $GROFF_SITE_FONT/devps
```

(後でスクリプトに)

## 日本語のフォントをスペシャルフォントとして扱う

フォント T (Times) のグリフの検索に M (Mincho) 追加します。
スペシャルフォントは
[Special Fonts](https://www.gnu.org/software/groff/manual/html_node/Special-Fonts.html)
に説明があります。

1. fspecial で T* と M* を対応付けます。

とりあえず、

```
$ vi ps.local
.fspecial TR MR
.fspecial TI MR
.fspecial TB MR
.fspecial TBI MR
```

2. ps.local は ps.tmac でインクルードします。

```
$ cp $GROFF_TMAC/ps.tmac .
$ echo .do mso ps.local >>ps.tmac
$ sudo install -m 644 ps.tmac $GROFF_SITE_TMAC/
```

3. MR (Roman) の他に Italic と Bold も使うなら、
fontforge で .ttf を作成して groff の site-fonts にコピーします。

M* の他に G* もあり、以下のフォントについて、上記を繰り返します。

* MR IPAMincho.ttf
* MI IPAMincho-Italic.ttf
* MB IPAMincho-Bold.ttf
* MBI IPAMincho-BoldItalic.ttf
* GR IPAGochic.ttf
* GI IPAGochic-Italic.ttf
* GB IPAGothic-Bold.ttf
* GBI IPAGothic-BoldItalic.ttf

4. ps.local に追加分の Tx (Times-x) と Mx (Mincho-x) の対応を加えます。

たとえば、

```
vi ps.local
.fspecial TR MR
.fspecial TI MI
.fspecial TB MB
.fspecial TBI MBI
.fspecial HR GR
.fspecial HI GI
.fspecial HB GB
.fspecial HBI GBI
```

## 日本語のマンページの ps を作る

```
$ zcat /usr/share/man/ja/manx/コマンド名.x.gz | \
  $GROFF -S -man -dlocale=ja.UTF-8 -DUTF-8 -KEUC-JP -t > a.ps
```

日本語のマンページ euc-jp から utf8 への変換に preconv を使いました。


## お好みで、たとえば、

1. man マクロで行間の詰まりすぎを補正します。

```
$ vi man_ja.local
.am1 TH
.  if t \{\
.      nr VS +(\\n[VS]u * 50 / 100)
.      ps \\n[PS]u
.      vs \\n[VS]u
.      ll \\n[LL]u
.  \}
```

2. 同様に mdoc マクロも補正します。

```
$ vi mdoc_ja.local
.if t .vs +(\n[.v]u * 50 / 100)
```

3. 日本語のマンページで nroff のために補正されているものを見直します。

マンページの中に na で行揃えを抑止しているものがありますが、
troff ではそう悪くはありません。na を n (nroff) のときだけにします。

```
$ vi コマンド名.1
.if n .na
```

ハイフネーションも同様なら、

```
.if n .fy 0
```
