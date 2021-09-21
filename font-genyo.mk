# install fonts to use groff in japanese

include use-groff.mk

REPOM=		genyo-font
REPOG=		genyog-font
SERIF=		GenYoMin
SANS=		GenYoGothic

VPATH=		$(patsubst %,%/ttc,${REPOM} ${REPOG})

setup::
	for f in ${REPOM} ${REPOG}; do \
	  [ -d $$f ] || git clone --depth 1 https://github.com/ButTaiwan/$$f.git; \
	done

veryclean::
	rm -rf ${REPOM} ${REPOG}

FF_BOLD=

include font-common.mk

${REPOM}/ttc/${SERIF}-R.ttc:	setup
${REPOG}/ttc/${SANS}-R.ttc:	setup

${REPOM}/ttc/${SERIF}-B.ttc:	setup
${REPOG}/ttc/${SANS}-B.ttc:	setup

all::	$M-$R.ttx $M-$R.ttf $G-$R.ttx $G-$R.ttf \
	$M-$B.ttx $M-$B.ttf $G-$B.ttx $G-$B.ttf

%.ttf:	%.ttx fonttools.pkg
	ttx -o $@ $<

%$(CN)-$R.ttx:	%-R.ttc fonttools.pkg
	ttx -o $@ -y 1 $<

%$(CN)-$B.ttx:	%-B.ttc fonttools.pkg
	ttx -o $@ -y 1 $<

clean::
	rm -f ${SERIF}*.ttx ${SANS}*.ttx
	rm -f ${SERIF}*.ttf ${SANS}*.ttf
