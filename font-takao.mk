# install fonts to use groff in japanese

include use-groff.mk

ifeq ("${OS}", "ubuntu")
FONT_PKG=	fonts-takao.pkg
FONT_MR=	/usr/share/fonts/truetype/takao-mincho/TakaoMincho.ttf
FONT_GR=	/usr/share/fonts/truetype/takao-gothic/TakaoGothic.ttf
SERIF=		TakaoMincho
SANS=		TakaoGothic
endif

ifeq ("${OS}", "freebsd")
FONT_PKG=	ja-font-takao.pkg
FONT_MR=	/usr/local/share/fonts/takao/TakaoExMincho.otf
FONT_GR=	/usr/local/share/fonts/takao/TakaoExGothic.otf
SERIF=		TakaoExMincho
SANS=		TakaoExGothic
endif

include font-common.mk

setup::	$(FONT_PKG)

$M-$R.sfd:	${FONT_MR} fontforge.pkg
	fontforge -lang=ff -c '$(FF_SAVE)' $< $@

$G-$R.sfd:	${FONT_GR} fontforge.pkg
	fontforge -lang=ff -c '$(FF_SAVE)' $< $@

clean::
	rm -f $M-$R.sfd
	rm -f $G-$R.sfd
