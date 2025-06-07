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

To use other fonts, such as Takao (Takao Mincho / Gothic) and
Source ([Source Han Sans][] / [Source Han Serif][]), 
use font-takao.mk and font-source.mk like this:

[Source Han Sans]: https://github.com/adobe-fonts/source-han-sans
[Source Han Serif]: https://github.com/adobe-fonts/source-han-serif

```
make -f font-takao.mk clean install
```

All Japanese fonts are installed under the names MR and GR, with MR
designated as a special font for TR (GR for HR).  Therefore, the
installed Japanese fonts will be used as needed even if they are not
specified.

* 20250607
I've put prototypes of gropdf(1) and afmtodit(1) with OTF support in [gropdf-otf][].
[gropdf-otf]: https://github.com/obuk/gropdf-otf
This prototype uses PDF's Tm operators for italics and vertical writing.
This will reduce font installation time and the number of fonts embedded in the PDF.
