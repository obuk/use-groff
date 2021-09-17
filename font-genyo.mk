# install fonts to use groff in japanese

include use-groff.mk

FONTS=		genyo-font genyog-font
SERIF=		GenYoMin
SANS=		GenYoGothic

VPATH=		$(patsubst %,%/ttc,${FONTS})

setup::
	for f in ${FONTS}; do \
	  [ -d $$f ] || git clone --depth 1 https://github.com/ButTaiwan/$$f.git; \
	done

veryclean::
	rm -rf ${FONTS}

FF_BOLD=
KEEP_SUFFIXES=	.TTF .ttf
include font-common.mk

%.ttf:	%.ttx fonttools.pkg
	ttx -o $@ $<

%JP-$(B).ttx:	%-B.ttc fonttools.pkg
	ttx -o $@ -y 1 $<

%JP-$(R).ttx:	%-R.ttc fonttools.pkg
	ttx -o $@ -y 1 $<
