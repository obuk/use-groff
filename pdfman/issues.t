.TH ISSUES 7 "17 Apr 2020"
.ds L" \[u201C]
.ds R" \[u201D]
.ds C` \f(CW\s-1
.ds C' \s+1\fP
.SH NAME
issues - using pdfhref in app.pl.
.
.SH SYNOPSIS
.
.EX
\&cd pdfman
\&morbo app.pl
.EE
.
.SH DESCRIPTION
.
日本語のマンページを
.BR groff (1)
を使って pdf に出力し、ブラウザで参照します。課題は、ここにまとめよう
と思います。
.
.PP
pdf ドライバの修正は Deri さんからたくさんの助言を頂きました。
.
この課題のページも
.UR https://lists.gnu.org/archive/html/groff/
groff mailing lists
.UE
から pdfman を取り出し、
.UR https://metacpan.org/pod/Mojolicious
Mojolicious
.UE
と組合せて使いました。
.
.SH "pre-grops.pl"
.SS "改行が失われる"
.UR http://localhost:3000/man/5/ppm
SEE ALSO in ppm(5)
.UE
改行は、欧文ではワードスペースのように扱われますが、日本語では伸縮可能
なゼロ幅スペースとして扱います。ただし、空行は段落の区切りとして残しま
す。
.
.SS ".TP のラベルが切れる"
\&.TP は次の 1行をラベルとして扱いますが、日本語の両端揃えの際、字間調
整にマクロを使用するとラベルが分割されます。
.PP
例えば、
.BR feature_test_macros (7)
中の \&.TP のタグ「_ISOC99_SOURCE (glibc 2.1.3 以降)」は次のように整形
されます。
.PP
.EX
\&_ISOC99_SOURCE (glibc 2.1.3 以
\&       降) ISO C99 標準に準拠した宣言を公開する。
.EE
期待される整形結果は次のとおりです。
.PP
.EX
\&_ISOC99_SOURCE (glibc 2.1.3 以降)
\&       ISO C99 標準に準拠した宣言を公開する。
.EE
.PP
この問題について、いま可能な選択肢は、(1)
.BR "そのまま使用する" 、
(2)
.B "groff を修正する"
の 2つです。(1) は、字間の調整を止めるか、問題があることを理解した上で
使います。(2) は \&.ss リクエストのワードスペースサイズの調整を未使用
のエスケープを割り当てるので groff を修正します。
.
.PP
当面の間 (2) を選び、副作用があれば (1) を選ぶか、新しい選択肢を考えよ
うと思います。2つの選択は、\%Vagrantfile の provision で決まります。使
用ポートと合わせて適宜書き直します。
.
.IP (1) 4
そのまま使用する
.IX そのまま使用する
.EX
\&config.vm.provision :shell, inline: <<-SHELL
\&sudo -u vagrant -i make -C /vagrant clean apt-upgrade
\&sudo -u vagrant -i make -C /vagrant clean install
\&sudo -u vagrant -i make -C /vagrant -f /vagrant/pdfman.mk clean all
\&SHELL
\&config.vm.network :forwarded_port, guest: 3000, host: 3000
.EE
.
.IP (2)
groff を修正する
.IX "groff を修正する"
.EX
\&config.vm.provision :shell, inline: <<-SHELL
\&sudo -u vagrant -i make -C /vagrant clean apt-upgrade
\&sudo -u vagrant -i make -C /vagrant clean install
\&sudo -u vagrant -i make -C /vagrant -f /vagrant/groff.mk clean install
\&sudo -u vagrant -i make -C /vagrant clean install
\&sudo -u vagrant -i make -C /vagrant -f /vagrant/pdfman.mk clean all
\&SHELL
\&config.vm.network :forwarded_port, guest: 3000, host: 3000
.EE
.
.SH "pdfman/app.pl"
.SS ".BR のマンページ"
.UR http://localhost:3000/man/5/pbm#SEE-ALSO
SEE ALSO in pbm(5)
.UE
.PP
1つの \&.BR で複数のマンページを表すものもあります。
.EX
\&.BR libpbm (3), pnm (5), pgm (5), ppm (5)
.EE
.
.SS ".UR 〜 .UE 中のリクエスト"
.UR http://localhost:3000/man/7/roff?lang=en#The-predecessor-RUNOFF
The predecessor RUNOFF in groff(7)
.UE
.PP
\&.UR 〜 \&.UE は間に置かれたテキストをアンカーに使います。テキストは
\&.B や \&.I で表わされることもあるので、\&.pdfhref を使う際は必要なら
\\f を用いて書き直します（ただし色は指定しない）。
.PP
.BR TBD :
\&.B や \&.I も同じ行にテキストが置かれていないとき \&.TP と同様に次の
1行を対象として扱います。\&.SM や \&.SB も同様です。これらを組合せもあ
ります。
.EX
\&.UR http://\:www.multicians.org
\&.I Multics
\&system
\&.UE .
.EE
.
.SS "Unknown のリンク"
.UR http://localhost:3000/man/7/groff?lang=en#See-Also
See Also in groff(7)
.UE
.PP
\&.UR 〜 \&.UE が空（アンカーテキストがない）のとき、\&.pdfhref は
Unknown のリンクを作る。空のときは URI を使う。
.EX
\&.TP
\&.I Wikipedia
\&article about
\&.I groff
\&.UR https://\:en.wikipedia.org/\:wiki/\:Groff_%28software%29
\&.UE .
.EE
.
.SS ".UR は様々な uri が書ける"
.UR http://localhost:3000/man/7/groff?lang=en#See-Also
See Also in groff(7)
.UE
.
.PP
たとえば、アクセス方法の分らない uri が書けます。とりあえず、https://
を付けます。
.EX
\&.I Tutorial about groff
\&.UR dl.dropbox.com/u/4299293/grofftut.pdf
\&Manas Laha - An Introduction to the GNU Groff Text Processing System
\&.UE
.EE
.
.SS "マンページのハイフネーション"
.UR http://localhost:3000/man/1/groff?lang=en#Preprocessors
Preprocessors in groff(1)
.UE
.PP
ハイフネーションを制御するエスケープ \e% を取り除かなければなりません。
.EX
\&.TP
\&.BR \e%soelim (1)
for including macro files from standard locations,
.EE
.
.SS "マンページとして扱わないもの"
.UR http://localhost:3000/man/1/tbl?lang=en#Global-options
Global options in tbl(1)
.UE
.PP
マンページのセクション番号は、たとえば 1x のように、単なる番号というわ
けではありません。このアプリケーションでは \f(CW/\ed[\ed\ew]*/\fP とし
ます。
.
.EX
\&.TP
\&.BI delim( xy )
\&Use
\&.I x
\&.RI and\~ y
\&as start and end delimiters for
\&.BR eqn (1).
.EE
.
.SS ".IX をブックマークに"
.UR http://localhost:3000/man/5/ppm?lang=en#PPM-file-format
PPM file format in ppm(5)
.UE ,
.UR http://localhost:3000/man/5/ppm?lang=en#magic-numbers
magic numbers in ppm(5)
.UE
.PP
\&.IX は、
.UR https://www.gnu.org/software/groff/manual/html_node/Additional-ms-Macros.html#Additional-ms-Macros
groff macros not appearing in AT&T troff
.UE
では \&.IX は \*(L"Indexing term (printed on standard error).\*(R" と
説明されていますが、ここでは \&.SH や \&.SS に続く、レベル3のしおりと
して扱います。
.EX
\&.SH DESCRIPTION
\&The portable pixmap format is a lowest common denominator color image
file format.
\&.IX "PPM file format"
.EE
.
.\" End

