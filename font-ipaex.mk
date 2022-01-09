# install fonts to use groff in japanese

include use-groff.mk

ifeq ("${OS}", "ubuntu")
FONT_PKG=	fonts-ipaexfont.pkg
FONT_MR=	/usr/share/fonts/opentype/ipaexfont-mincho/ipaexm.ttf
FONT_GR=	/usr/share/fonts/opentype/ipaexfont-gothic/ipaexg.ttf
endif

ifeq ("${OS}", "freebsd")
FONT_PKG=	ja-font-ipaex.pkg
FONT_MR=	/usr/local/share/fonts/ipaex/ipaexm.otf
FONT_GR=	/usr/local/share/fonts/ipaex/ipaexg.otf
endif

SERIF=		IPAexMincho
SANS=		IPAexGothic
CN=

include font-common.mk

setup::		${FONT_PKG}

${FONT_MR}:	${FONT_PKG}
${FONT_GR}:	${FONT_PKG}

$M-$R.sfd:	${FONT_MR} fontforge.pkg
	fontforge -lang=ff -c '$(FF_SAVE)' $< $@

$G-$R.sfd:	${FONT_GR} fontforge.pkg
	fontforge -lang=ff -c '$(FF_SAVE)' $< $@

clean::
	rm -f $M-$R.sfd
	rm -f $G-$R.sfd
