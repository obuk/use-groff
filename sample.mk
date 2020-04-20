include use-groff.mk

ifeq ("$(OS)", "ubuntu")
setup::	nkf.pkg
endif
ifeq ("$(OS)", "freebsd")
setup::	ja-nkf.pkg
endif
all::	setup

lang?=		ja
GS_PDFWRITE?=	gs -sDEVICE=pdfwrite -dPrinted=false -dNOPAUSE -dQUIET -dBATCH \
		-sFONTPATH=${SITE_FONT}/devps:${GROFF_FONT}/devps -sOutputFile=- -

GROFF_ENV?=	GROFF_TMAC_PATH=/vagrant/files
GROFF_PATH=	${GROFF_BIN}/groff
GROFF?=		env ${GROFF_ENV} ${GROFF_PATH} -VV -P-pa4 -dpaper=a4 -Kutf8

PDFMAN=		(path=$$(man -w -L${lang} $$(sed -e 's/\(.*\)_\([0-9]\)/\2 \1/')); \
		mlang=$$(echo $$path | tr / '\n' | sed -n '/^${lang}$$/s//-m&/p'); \
		(zcat $$path 2>/dev/null || cat $$path) | nkf -w | \
		${GROFF} -Tpdf -P-d -mandoc -k $$mlang)

.SUFFIXES: .pdf
all::	gropdf_1.pdf groff_char_7.pdf groff_mdoc_7.pdf patch_1.pdf

clean::
	rm -f gropdf_1.pdf
	rm -f groff_mdoc_7.pdf
	rm -f groff_char_7.pdf
	rm -f patch_1.pdf


all::	sample.pdf

.PHONY:	sample.pdf
sample.pdf:	sample.7
	${GROFF} -Tpdf -mandoc -mja $< | ${GS_PDFWRITE} > $@

clean::
	rm -f sample.pdf

all::	perl.pdf

perl.pdf:
	perldoc.sh --pdf -L${lang} perl > $@

clean::
	rm -f perl.pdf

# https://lists.gnu.org/archive/html/groff/2019-08/msg00000.html
# [groff] Unicode fonts output

LETTER_ORIG=	https://lists.gnu.org/archive/html/groff/2019-08/txtqtVQY7Ql6Z.txt
LETTER_DERI=	https://lists.gnu.org/archive/html/groff/2019-08/txtrEepUiAFDJ.txt

all::	letter.pdf

clean::
	rm -f letter.mom
	rm -f letter.pdf

letter.mom:
	[ -f $@ ] || curl -Ls $(LETTER_DERI) >$@

%.pdf:	%.mom
	pdfmom $< >$@

%.pdf:	setup
	echo $* | ${PDFMAN} > $@

clean::
	rm -f a.pdf
