# make groff box to format Japanese

Create a ubuntu box with groff installed and output Japanese ps and
pdf with groff.  It's still experimental.

```
ln -sf Vagrantfile.ubuntu Vagrantfile
vagrant up
vagrant ssh
cd /vagrant
man -t -Lja 7 groff > a.ps
man -Tpdf -Lja 7 groff > a.pdf
```

Use MANROFFOPT to specify groff options in man command.
To embed a PDF font, use gs like this:

```
man -Tpdf -Lja groff |gs -sDEVICE=pdfwrite -sOutputFile=- - >a.pdf
```

Install [Sauce Han Sans / Sauce Han Serif for Japanese][] as the
default Japanese font.  The installation method is based on Peter
Schaffter's [Adding fonts to groff][].  It's also briefly described in
grops(1) and gropdf(1) if you have a recent groff installation.

[Adding fonts to groff]: http://www.schaffter.ca/mom/momdoc/appendices.html#fonts
[Sauce Han Sans / Sauce Han Serif for Japanese]: https://github.com/3846masa/sauce-han-fonts

To use other fonts, such as Takao and Noto, use font-takao.mk and
font-noto.mk like this:

```
make -f font-takao.mk clean install
```

All Japanese fonts are installed under the names MR and GR, with MR
designated as a special font for TR (GR for HR).  Therefore, the
installed Japanese fonts will be used as needed even if they are not
specified.
