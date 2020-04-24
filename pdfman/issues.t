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
で pdf に出力し、
.UR https://metacpan.org/pod/Mojolicious
Mojolicious
.UE
で小さなウェブサービスと組み合わせました。
.
pdf のリンクは pdfman がベースです。
.UR https://lists.gnu.org/archive/html/groff/
groff mailing lists
.UE
にあります。
.
課題はリンクで指せると分りやすいので、マンページの中にまぜておこうと思
います。
.
.PP
pdf ドライバの修正も含め、Deri さんから多くの助言を頂きました。
.
ありがとうございます。
.
.SH "pre-grops.pl"
.SS "改行が失われる"
.UR http://localhost:3000/man/5/ppm#DESCRIPTION
SEE ALSO in ppm(5)
.UE
.PP
改行は、欧文ではワードスペースのように扱われますが、日本語では伸縮可能
なゼロ幅スペースとして扱います。
.
しかし、空行は段落の区切りとして残します。
.
.SS ".TP のラベルが切れる"
.BR feature_test_macros (7)
.PP
\&.TP のラベルの1つ「_ISOC99_SOURCE (glibc 2.1.3 以降)」は次のように整
形されます。「以」までがラベルとして扱われ、「降」は次の段落に送られま
す。
.sp 0.5
.EX
\&_ISOC99_SOURCE (glibc 2.1.3 以
\&       降) ...
.EE
.PP
両端揃えのために文字間に伸縮可能なゼロ幅スペースのマクロを挟むからです。
\&.TP のラベルは 1行分です。マクロを挟むとき改行も入り、それが行を終わ
らせます。
.PP
この問題について、いま可能な選択肢は、(1)
.BR "そのまま使用する" 、
(2)
.B "groff を修正する"
の 2つです。(1) は、問題があることを理解した上で使う（両端揃えをしない
か、字間を調整せず約物の前後のスペースのみ調整する）という選択です。
(2) はマクロでなくエスケープを使う（\&.ss リクエストのワードスペースサ
イズの調整を未使用のエスケープを割り当てる）という選択です。従って
groff を修正します。
.
.PP
当面の間 (2) を選び、副作用があれば (1) を選ぶか、新しい選択肢を考えよ
うと思います。2つの選択は、\%Vagrantfile の provision で決まります。使
用ポートと合わせて適宜書き直します。
.
.IP (1) 4
そのまま使用する
.IX そのまま使用する
.sp 0.3
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
.sp 0.3
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
.SS ".BR で表わされたマンページ"
.UR http://localhost:3000/man/5/pbm#SEE-ALSO
SEE ALSO in pbm(5)
.UE
.PP
\&.BR や \&.IR で表わされたマンページをリンクに直します。1つの \&.BR
で複数のマンページを表わすこともあります。
.sp 0.5
.EX
\&.BR libpbm (3), pnm (5), pgm (5), ppm (5)
.EE
.
.SS ".UR 〜 .UE 中の \&.B や \&.I"
.UR http://localhost:3000/man/7/roff?lang=en#The-predecessor-RUNOFF
The predecessor RUNOFF in groff(7)
.UE
.PP
\&.UR 〜 \&.UE 中のテキストはアンカーとして使われます。\&.pdfhref に渡
すとき \&.B や \&.I はエスケープを使って書き直します（色は使えません）。
.PP
.BR TBD :
\&.B や \&.I も同じ行にテキストが置かれていないとき \&.TP と同様に次の
1行を対象として扱います。\&.SM や \&.SB も同様です。これらの組合せもあ
ります。
.sp 0.5
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
\&.UR 〜 \&.UE が空（アンカーテキストなし）のとき、リンクは Unknown と
表示されます。
.sp 0.5
.EX
\&.TP
\&.I Wikipedia
\&article about
\&.I groff
\&.UR https://\:en.wikipedia.org/\:wiki/\:Groff_%28software%29
\&.UE .
.EE
.PP
このような場合に URI から分ることもあるので、
.UR https://metacpan.org/pod/URI::Escape
uri_unescape
.UE
でテキストに直します。
.
.SS ".UR の uri と .pdfhref -D"
.UR http://localhost:3000/man/7/groff?lang=en#See-Also
See Also in groff(7)
.UE
.
.PP
\&.UR と同じ行に書かれる uri は検証されることがありません。
.
省略されて曖昧なところは、\&.pdfhref の実装に依存します。
.
次の例はアクセス方法が省略されているので、http:// を補います。
.sp 0.5
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
ハイフネーションを制御するエスケープ \e% は取り除きます。
.sp 0.5
.EX
\&.TP
\&.BR \e%soelim (1)
for including macro files from standard locations,
.EE
.
.SS "マンページのセクション"
.UR http://localhost:3000/man/1/tbl?lang=en#Global-options
Global options in tbl(1)
.UE
.PP
セクションのパターンを緩くし過ぎないように。
.
.sp 0.5
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
に \*(L"Indexing term (printed on standard error).\*(R" と説明されてい
ますが、\&.SH や \&.SS に続くレベル3のしおりとして扱います。
.sp 0.5
.EX
\&.SH DESCRIPTION
\&The portable pixmap format is a lowest common denominator color image
file format.
\&.IX "PPM file format"
.EE
.
.\" End
