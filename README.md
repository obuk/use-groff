# using-grops

FreeBSD の日本語のマンページを ports の textproc/groff で ps にします。
euc-jp より utf8 を使いたい人向けですが、Linux でも同様だと思います。

## はじめに

[FreeBSDの日本語マニュアル(2)](https://qiita.com/false-git@github/items/d1eb2f680801a1a75edb)
を参照して、日本語のマンページを utf8 で扱えるようにしてください。

## fontforge と日本語のフォント

groff の ps ドライバ grops で使えるフォントの作成と追加の手順は
http://www.schaffter.ca/mom/momdoc/appendices.html に説明されています。
フォントは ttf から作りますが、使えないフォントもあります。

次の例は ja-font-std をインストールし、
その中の *.gs7 を PS の Fontname に直します。

```
$ sudo pkg install fontforge ja-font-std
$ ln -s /usr/local/share/fonts/std.ja_JP/Ryumin-Light.gs7 IPAMincho.ttf
$ ln -s /usr/local/share/fonts/std.ja_JP/GothicBBB-Medium.gs7 IPAGothic.ttf
```

ファイル名は PS の Fontname に直します。後で fontforge でイタリックや
ボールどの派生フォントを作成すると、ファイルは、デフォルトでは PS の
Fontname になるので、ja-font-std のフォントもこの名前に直します。

PS の Fontname は、fontforge で [Element] - [Font Info...]
(Ctrl+Shift+F) の Font Information で確認できます。

## groff (grops) フォントの作成とインストール

fontforge のスクリプトを使って ttf から afm と t42 を作り、そこから
groff (grops) のフォントを作って、site-fonts にコピーします。

```
$ cat > generate.pe <<EOF
Open(\$1);
Generate(\$fontname + ".afm");
Generate(\$fontname + ".t42");
EOF
$ fontforge -script generate.pe IPAMincho.ttf
$ ln -s $GROFF_FONT/devps/generate/textmap .
$ perl `which afmtodit` -s -i0 -m IPAMincho.afm textmap MR
$ echo IPAMincho IPAMincho.t42 >>download
$ sudo mkdir -p $GROFF_SITE_FONT/devps
$ sudo install -m 644 MR IPAMincho.t42 download $GROFF_SITE_FONT/devps
```

上で PS の Fontname を fontforge の Font Information で確認しましたが、
GUI なしなら、この afm ファイル中の Fontname を参照してください。
download ファイルは、ps に埋め込むフォントを列挙します。

(後でスクリプトに)

## スペシャルフォントの利用

スペシャルフォントを使うと、たとえば、フォント T (Times) に M (Mincho)
追加することができます。スペシャルフォントは
[Special Fonts](https://www.gnu.org/software/groff/manual/html_node/Special-Fonts.html)
に説明があります。

T* と M* は、次に示す ps.local (ファイル名は何でも) を作り、
fspecial で 2つの対応を与えます。

```
$ vi ps.local
.fspecial TR MR
.fspecial TI MR
.fspecial TB MR
.fspecial TBI MR
```

作成した ps.local は ps.tmac でインクルードします。

```
$ cp $GROFF_TMAC/ps.tmac .
$ echo .do mso ps.local >>ps.tmac
$ sudo install -m 644 ps.tmac $GROFF_SITE_TMAC/
```

MR (Mincho Roman、オリジナルフォント) に加え Italic や Bold も作るなら、
fontforge でその ttf を作成し、更に afm と t42 や download ファイルも
作成し、 groff にコピーします。

M* の他に G* もあるので、ひととおり作る場合は、以下のフォントについて、
上記を繰り返してください。

* MR IPAMincho.ttf
* MI IPAMincho-Italic.ttf
* MB IPAMincho-Bold.ttf
* MBI IPAMincho-BoldItalic.ttf
* GR IPAGochic.ttf
* GI IPAGochic-Italic.ttf
* GB IPAGothic-Bold.ttf
* GBI IPAGothic-BoldItalic.ttf

それから ps.local にいま作成したフォントの Tx と Mx の対応を追加します。
追加後の ps.local の例を示します。

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

日本語のマンページ euc-jp から utf8 への変換には preconv を使いました。


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

マンページの中に na で行揃えを抑制しているものがありますが、
troff ではそう悪くはありません。na を n (nroff) のときだけにします。

```
$ vi コマンド名.1
.if n .na
```

ハイフネーションも同様なら、

```
.if n .fy 0
```
