# install fonts to use groff in japanese

include use-groff.mk

FONT?=		sauce-han-fonts
FONT_URL?=	https://github.com/3846masa/${FONT}.git

setup::
	[ -d ${FONT} ] || git clone ${FONT_URL} ${FONT}

veryclean::
	$(MAKE) -f $(firstword $(MAKEFILE_LIST)) clean
	rm -rf ${FONT}


SERIF?=		SauceHanSerif
SANS?=		SauceHanSans
CN?=		JP

FAM?=		M G

M?=		${SERIF}${CN}
G?=		${SANS}${CN}

STY?=		R B

R?=		Regular
I?=		Italic
B?=		Bold
BI?=		BoldItalic

VPATH=		${FONT}/${SERIF} ${FONT}/${SANS}

TTFS=		$(foreach fam, ${FAM}, $(foreach sty, ${STY}, $($(fam))-$($(sty)).TTF))
TEXTMAPS=	$(patsubst %.TTF, %.textmap, ${TTFS})

all::	${TTFS} ${TEXTMAPS}

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

MAKE_TEXTMAP_TEXTMAP?=	env \
		GROFF_BIN_PATH=${GROFF_BIN} \
		GROFF_FONT_PATH=${GROFF_FONT} \
		${MAKE_TEXTMAP} $(or ${TEXTMAP_LOCAL}, textmap)

%.textmap:	%.TTF ${MAKE_TEXTMAP}
	@echo ${MAKE_TEXTMAP_TEXTMAP} $< \>$@
	@bash -l -c '${MAKE_TEXTMAP_TEXTMAP} $<' >a.textmap && mv a.textmap $@

clean::
	rm -f $M-*.textmap
	rm -f $G-*.textmap

${MAKE_TEXTMAP}:	Font-TTF.cpanm File-Spec.cpanm

clean::
	rm -f Font-TTF.cpanm File-Spec.cpanm

%.TTF:	%.ttf fontforge.pkg
	fontforge -lang=ff -c 'Open($$1); RenameGlyphs("Adobe Glyph List"); Generate($$2)' $< $@

clean::
	rm -f $M-*.TTF
	rm -f $G-*.TTF
