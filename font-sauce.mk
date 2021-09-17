# install fonts to use groff in japanese

include use-groff.mk

FONTS=		sauce-han-fonts
SERIF=		SauceHanSerif
SANS=		SauceHanSans

VPATH=		$(patsubst %,%/${SERIF},${FONTS}) $(patsubst %,%/${SANS},${FONTS})

setup::
	for f in ${FONTS}; do \
	  [ -d $$f ] || git clone --depth 1 https://github.com/3846masa/$$f.git; \
	done

veryclean::
	rm -rf ${FONTS}

FF_BOLD=
include font-common.mk
