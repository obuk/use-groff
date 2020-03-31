# groff で日本語を処理する

groff をインストールした ubuntu box を作ります。
groff で日本語の ps と pdf を出力できます。

```
vagrant up
vagrant ssh
cd /vagrant
man -t -Lja 7 groff > a.ps
man -Tpdf -Lja 7 groff > a.pdf
```

## 日本語のフォント

フォントは type42 形式でインストールします。

インストール方法は、Peter Schaffter さんの [Adding fonts to groff][] にあります。
最近の groff をインストールしていれば grops(1) や gropdf(1) にも同様の説明があります。

日本語のフォントは [Sauce Han Sans / Sauce Han Serif for Japanese][] を選びました。

[Adding fonts to groff]: http://www.schaffter.ca/mom/momdoc/appendices.html#fonts
[Sauce Han Sans / Sauce Han Serif for Japanese]: https://github.com/3846masa/sauce-han-fonts

### Times と Mincho

groff はデフォルトのフォントに T (Times) ファミリを使います。
日本語の字体を含まないので、[Special Fonts][] で追加します。
次の例は T* に M* (明朝) を追加します。

```
$ vi ps.local
.fspecial TR MR
.fspecial TI MR
.fspecial TB MB
.fspecial TBI MB
```

[Special Fonts]: https://www.gnu.org/software/groff/manual/html_node/Special-Fonts.html


### フォントの埋め込み

ビューワにも依りますが、pdf で文字化けが生じるとき、
フォントを埋め込むことで対処できることが多いと思います。
次の例は gs を使ってフォントを埋め込みます。

```
$ man -Tpdf -Lja コマンド名 | \
  gs -sDEVICE=pdfwrite -dPrinted=false -dNOPAUSE -dQUIET -dBATCH -sOutputFile=- - >a.pdf
```

埋め込みは pdf ドライバのオプションにもありますが、
出力ファイルが大きくなるので、おすすめではありません。

### mdoc マクロ

mdoc マクロは、日本語では mdoc/ja.UTF-8 を使いますが、
ubuntu の groff パッケージ中になさそうに見えるので、
freebsd の [tmac-20030521_2.tar.gz][] に含まれるものを使いました。
説明は false at wizard-limit.net さんの [FreeBSDの日本語マニュアル(2)][] にあります。

[tmac-20030521_2.tar.gz]: http://distcache.FreeBSD.org/local-distfiles/hrs/tmac-20030521_2.tar.gz
[FreeBSDの日本語マニュアル(2)]: https://qiita.com/false-git@github/items/d1eb2f680801a1a75edb

### 日本語の pod

日本語 pod も groff を使って ps、pdf に出力できます。

```
$ perldoc.sh --pdf -Lja perl >a.pdf
```

[Pod::PerldocJP][] のラッパなので、日本語の pod を自動的にダウンロードします。
[Pod::PerldocJP]: https://metacpan.org/pod/distribution/Pod-PerldocJp/perldocjp


### 行間の補正

日本語のフォントは欧文のものより高さがあり、行間を広げた方が読みやすいと思うので、
man.local と mdoc.local の中で調整しています。

対象が日本語であることを知るために locale を参照しています。
これは freebsd の man コマンドの方法を真似たものです。


### 行末揃えとハイフネーション

日本語のマンページには行末揃えやハイフネーションを抑止していますが、
freebsd では前処理プログラムの中で抑止したと思われるところを機械的に戻していましたが、
ubuntu ではそのままにしています。


### 異体字

unicode で統合される漢字、たとえば「視 uFA61」の「視 u8996」は、
groff の textmap で制御できます。
[ttf の cmap テーブル][]の UVS を参照するので、
UVS のないフォントは正しく表示できないかもしれません。

[ttf の cmap テーブル]: https://docs.microsoft.com/en-us/typography/opentype/spec/cmap
[Font::TTF]: https://metacpan.org/pod/Font::TTF

誤りや改善のご指摘がありましたら、お気軽にどうぞ。
