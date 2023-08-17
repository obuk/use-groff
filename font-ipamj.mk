# install fonts to use groff in japanese

include use-groff.mk

ifeq ("${OS}", "ubuntu")
FONT_PKG=	fonts-ipamj-mincho.pkg
FONT_MR=	/usr/share/fonts/truetype/ipamj/ipamjm.ttf
FONT_GR=
endif

SERIF=		IPAmjMincho
SANS=
CN=

FAM=		M
STY=		R I

include font-common.mk

setup::		${FONT_PKG}

${FONT_MR}:	${FONT_PKG}

$M-$R.sfd:	${FONT_MR} fontforge.pkg
	fontforge -lang=ff -c '$(FF_SAVE)' $< $@

clean::
	rm -f $M-$R.sfd
