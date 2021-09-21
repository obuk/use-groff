# install fonts to use groff in japanese

include use-groff.mk

REPO=		sauce-han-fonts
SERIF=		SauceHanSerif
SANS=		SauceHanSans

VPATH=		$(patsubst %,%/${SERIF},${REPO}) $(patsubst %,%/${SANS},${REPO})

setup::
	for f in ${REPO}; do \
	  [ -d $$f ] || git clone --depth 1 https://github.com/3846masa/$$f.git; \
	done

veryclean::
	rm -rf ${REPO}

FF_BOLD=

include font-common.mk

${REPO}/${SERIF}/$M-$R.ttf:	setup
${REPO}/${SANS}/$G-$R.ttf:	setup

${REPO}/${SERIF}/$M-$B.ttf:	setup
${REPO}/${SANS}/$G-$B.ttf:	setup
