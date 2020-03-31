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

#GROFF_PATH?=	/usr/local/bin/groff
GROFF_PATH?=	/usr/bin/groff

GROFF?=		env GROFF_TMAC_PATH=/vagrant/files:/etc/groff \
			GROFF_FONT_PATH=/usr/share/groff/site-font \
			GROFF_BIN_PATH=$(dirname ${GROFF_PATH}) ${GROFF_PATH} \
		-VV -man -mja -Tpdf -P-pa4 -dpaper=a4 -Kutf8

UMAN_PL?=	for (@ARGV) { \
			s/(.*?)(_([0-9]))?$$/"cat ".`man -w -L${lang} $$3 $$1`/e; \
			s/^/z/ if /[.]g?z$$/; \
			system $$_; \
		}

.SUFFIXES: .pdf
all::	gropdf_1.pdf groff_char_7.pdf groff_mdoc_7.pdf patch_1.pdf

%_1.pdf:	setup
	@#perl -e '$(UMAN_PL)' $(basename $@) | nkf -w | ${GROFF} | ${GS_PDFWRITE} > $@
	man -Tpdf -L${lang} `echo $* |sed 's/\(.*\)_\([0-9]\)/\2 \1/'` | ${GS_PDFWRITE} > $@
%_7.pdf:	setup
	@#perl -e '$(UMAN_PL)' $(basename $@) | nkf -w | ${GROFF} | ${GS_PDFWRITE} > $@
	man -Tpdf -L${lang} `echo $* |sed 's/\(.*\)_\([0-9]\)/\2 \1/'` | ${GS_PDFWRITE} > $@

gropdf_1.pdf:	$(MAKEFILE_LIST)
	man -Tpdf `echo $* |sed 's/\(.*\)_\([0-9]\)/\2 \1/'` | ${GS_PDFWRITE} > $@

clean::
	rm -f gropdf_1.pdf
	rm -f groff_mdoc_7.pdf
	rm -f groff_char_7.pdf
	rm -f patch_1.pdf


all::	sample.pdf

.PHONY:	sample.pdf
sample.pdf:	sample.7 $(MAKEFILE_LIST)
	${GROFF} $< | ${GS_PDFWRITE} > $@

clean::
	rm -f sample.pdf

all::	sample.pdf

.PHONY:	pre-grops.pdf
pre-grops.pdf:	pre-grops.1 $(MAKEFILE_LIST)
	${GROFF} $< | ${GS_PDFWRITE} > $@

clean::
	rm -f pre-grops.pdf

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

clean::
	rm -f a.pdf
