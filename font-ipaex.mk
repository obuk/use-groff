# install fonts to use groff in japanese

include use-groff.mk

ifeq ("${OS}", "ubuntu")
FONT_PKG?=	fonts-ipaexfont.pkg
FONT_MR?=	/usr/share/fonts/opentype/ipaexfont-mincho/ipaexm.ttf
FONT_GR?=	/usr/share/fonts/opentype/ipaexfont-gothic/ipaexg.ttf
SERIF?=		IPAexMincho
SANS?=		IPAexGothic
endif

ifeq ("${OS}", "freebsd")
FONT_PKG?=	ja-font-ipaex.pkg
FONT_MR?=	/usr/local/share/fonts/ipaex/ipaexg.otf
FONT_GR?=	/usr/local/share/fonts/ipaex/ipaexm.otf
SERIF?=		IPAexMincho
SANS?=		IPAexGothic
endif

setup::

${FONT_MR} ${FONT_GR}:	${FONT_PKG}

FAM?=		M G

M?=		${SERIF}
G?=		${SANS}

#STY?=		R I B BI
STY?=		R B

R?=		Regular
I?=		Italic
B?=		Bold
BI?=		BoldItalic

TTFS=	$(foreach fam, ${FAM}, $(foreach sty, ${STY}, $($(fam))-$($(sty)).TTF))

all::	${TTFS}

$M-$R.ttf:	${FONT_MR}
	ln -sf $< $@

$G-$R.ttf:	${FONT_GR}
	ln -sf $< $@

clean::
	rm -f $M-$R.ttf
	rm -f $G-$R.ttf


define install_font
install::	$(1)
$(1):	$(2).TTF $(2).textmap fontforge.pkg
	sudo env TEXTMAP=$(strip $(2)).textmap AFMTODIT="${AFMTODIT}" \
		GROFF_PREFIX="${GROFF_PREFIX}" \
		${INSTALL_FONT} $(1) $(2).TTF
endef

$(foreach fam, ${FAM}, $(foreach sty, ${STY}, \
  $(eval $(call install_font, $(fam)$(sty), $($(fam))-$($(sty)))) \
))

%.textmap:	%.TTF ${MAKE_TEXTMAP}
	@echo ${MAKE_TEXTMAP} $(or ${TEXTMAP_LOCAL}, textmap) $< \>$@
	@bash -l -c 'env GROFF_BIN_PATH=${GROFF_BIN} GROFF_FONT_PATH=${GROFF_FONT} ${MAKE_TEXTMAP} $(or ${TEXTMAP_LOCAL}, textmap) $<' >a.textmap && mv a.textmap $@

clean::
	rm -f $M-*.textmap
	rm -f $G-*.textmap

${MAKE_TEXTMAP}:	Font-TTF.cpanm File-Spec.cpanm

clean::
	rm -f Font-TTF.cpanm File-Spec.cpanm

%-$B.TTF:	%-$R.TTF
	${GENERATE_FONT} -n $B -t .TTF B $<
%-$I.TTF:	%-$R.TTF
	${GENERATE_FONT} -n $I -t .TTF I $<
%-${BI}.TTF:	%-$R.TTF
	${GENERATE_FONT} -n ${BI} -t .TTF BI $<

%.TTF:	%.ttf fontforge.pkg
	fontforge -lang=ff -c 'Open($$1); RenameGlyphs("Adobe Glyph List"); Generate($$2)' $< $@

clean::
	rm -f $M-*.TTF
	rm -f $G-*.TTF
