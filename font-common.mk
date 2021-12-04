# install fonts to use groff in japanese

include use-groff.mk

TYPE42_FONT?=	${SITE_FONT}/devps
EMBED?=		*
FOUNDRY?=
TEXT_ENC?=	text.enc

GS_ENABLE?=	yes

SERIF?=		Serif
SANS?=		Sans
CN?=		JP

FAM?=		M G

M?=		${SERIF}${CN}
G?=		${SANS}${CN}

STY?=		R I B BI

R?=		R
I?=		I
B?=		B
BI?=		BI

#R?=		Regular
#I?=		Italic
#B?=		Bold
#BI?=		BoldItalic

setup::

veryclean::
	$(MAKE) -f $(firstword $(MAKEFILE_LIST)) clean

all::	clean-download
	sudo mkdir -p ${TYPE42_FONT}
	sudo mkdir -p ${SITE_FONT}/devps
	sudo mkdir -p ${SITE_FONT}/devpdf

clean::	clean-download

clean-download:
	rm -f download.devps
	rm -f download.devpdf

TRY_JA_VARIANT_GLYPHS?=
ifneq "${TRY_JA_VARIANT_GLYPHS}" ""
AFMTODIT=	perl afmtodit.tmp
all::	afmtodit.tmp
clean::
	rm -f afmtodit.tmp
afmtodit.tmp:
	perl -w -lpe 's/^\s+"(?:F[9A][0-9A-F]{2}|2F[89][0-9A-F]{2}|2FA[01][0-9A-F])",\s+"[0-9A-F]+",$$/#$$&/' <${GROFF_BIN}/afmtodit >$@
endif

AFMTODIT+=	-s
ifneq "${TEXT_ENC}" ""
AFMTODIT+=	-e ${TEXT_ENC}
ifneq "${TEXT_ENC}" "text.enc"
all::	${TEXT_ENC}
${TEXT_ENC}:
	cd ${GROFF_FONT}/devps && sudo ln -sf text.enc ${TEXT_ENC}
endif
endif

define install_font
all::		$(patsubst %,$(2)%,.TTF)

install::	install-$(1)

install-$(1):	install-$(2)
	sed 's/^name .*/name $(1)/' ${SITE_FONT}/devps/$(2) >/tmp/$(1)
	sudo install -m 644 /tmp/$(1) ${SITE_FONT}/devps/
	sudo ln -sf ${SITE_FONT}/devps/$(1) ${SITE_FONT}/devpdf/$(1)

clean::
	rm -f /tmp/$(1)

install-$(2):	$(2) $(2).t42
	sudo install -m 644 $(2).t42 ${TYPE42_FONT}
	sudo install -m 644 $(2) ${SITE_FONT}/devps
	sudo ln -sf ${SITE_FONT}/devps/$(2) ${SITE_FONT}/devpdf/$(2)

download.devps::	$(2) $(2).t42
	printf "$(2)\t${TYPE42_FONT}/$(2).t42\n" >> $$@

download.devpdf::	$(2) $(2).t42
	printf "${FOUNDRY}\t$(2)\t${EMBED}${TYPE42_FONT}/$(2).t42\n" >> $$@

# afmtodit option: see /usr/share/groff/current/font/devps/generate/Makefile

$(2):	$(2).afm $(2).t42 $(2).textmap fontforge.pkg
	case $(2) in \
	*Italic) ${AFMTODIT} -i50 $(2).afm $(2).textmap $(2);; \
	*) ${AFMTODIT} -i0 -m $(2).afm $(2).textmap $(2);; \
	esac

clean::
	rm -f $(2)*
endef

install::	download.devps
	sudo install -m 644 $< ${SITE_FONT}/devps/download

install::	download.devpdf
	sudo install -m 644 $< ${SITE_FONT}/devpdf/download

$(foreach fam, ${FAM}, $(foreach sty, ${STY}, \
  $(eval $(call install_font,$(fam)$(sty),$($(fam))-$($(sty)))) \
))

ifeq "${GS_ENABLE}" "yes"
GS_FONTDIR?=	\
	$(shell gs --help \
	| sed -e '1,/^Search path/d' -e '/^[^ ]/d' \
	| tr ': ' '\n' \
	| grep local \
	| grep font \
	| head -1)

install::	download.devps ghostscript.pkg
	[ ! -z "${GS_FONTDIR}" ] && \
		echo run: env GS_FONTDIR=/usr/local/lib/ghostscript/fonts \
			$(MAKE) -f $(firstword $(MAKEFILE_LIST)) 
	sudo mkdir -p $(GS_FONTDIR)
	([ -f $(GS_FONTDIR)/Fontmap ] && cat $(GS_FONTDIR)/Fontmap; \
	 cat $< | while read fontname fontpath; do \
	   (cd ${SITE_FONT}/devps; \
	    [ -L $$fontpath ] && fontpath=$$(readlink $$fontpath); \
	    sudo ln -sf $$fontpath $(GS_FONTDIR); \
	    printf "/$$fontname ($$(basename $$fontpath));\n";) \
	 done) |sort -u >Fontmap
	sudo install -b -m 644 Fontmap $(GS_FONTDIR)
endif

MAKE_TEXTMAP_TEXTMAP?=	env \
		GROFF_BIN_PATH=${GROFF_BIN} \
		GROFF_FONT_PATH=${GROFF_FONT} \
		${MAKE_TEXTMAP} $(or ${TEXTMAP_LOCAL}, textmap)

%.textmap:	%.TTF ${MAKE_TEXTMAP}
	@echo ${MAKE_TEXTMAP_TEXTMAP} $< \>$@
	@bash -l -c '${MAKE_TEXTMAP_TEXTMAP} $<' >a.textmap && mv a.textmap $@


${MAKE_TEXTMAP}:	Font-TTF.cpanm File-Spec.cpanm

clean::
	rm -f Font-TTF.cpanm File-Spec.cpanm

FF_GENERATE=	\
		Open($$1); \
		SetFontNames($$2:r); \
		Generate($$2);

%.afm:	%.TTF
	fontforge -lang=ff -c '$(FF_GENERATE)' $< $@

%.t42:	%.TTF
	fontforge -lang=ff -c '$(FF_GENERATE)' $< $@

FF_BOLD?=	\
		Open($$1); \
		SelectAll(); \
		ClearInstrs(); \
		ExpandStroke(50, 0, 1, 0, 1); \
		SetFontNames($$2:r); \
		Generate($$2);

ifneq "${FF_BOLD}" ""
%-$B.TTF:	%-$R.TTF
	fontforge -lang=ff -c '$(FF_BOLD)' $< $@
endif

FF_ITALIC?=	\
		Open($$1); \
		SelectAll(); \
		ClearInstrs(); \
		Skew(13); \
		SetFontNames($$2:r); \
		Generate($$2);

ifneq "${FF_ITALIC}" ""
%-$I.TTF:	%-$R.TTF
	fontforge -lang=ff -c '$(FF_ITALIC)' $< $@

%-${BI}.TTF:	%-$B.TTF
	fontforge -lang=ff -c '$(FF_ITALIC)' $< $@
endif


#Based: Adobe Glyph List, AGL For New Fonts, AGL without afii, AGL with PUA
AGL?=	Adobe Glyph List

ifneq "${TEXT_ENC}" ""
FF_AGL-text.enc?=	\
		Open($$1); \
		LoadNamelist("AGL-text.enc.nam"); \
		RenameGlyphs("AGL-text.enc"); \
		SetFontNames($$2:r); \
		Generate($$2);

AGL-text.enc.pl?=\
	use strict;\
	use warnings;\
	use feature "say";\
	use Slurp;\
	exit 1 unless my $$afmtodit = slurp "${GROFF_BIN}/afmtodit";\
	say "Based: $(AGL)";\
	if ($$afmtodit =~ /%AGL_to_unicode\s*=\s*(\(.*?\))\s*;/s) {\
	  my %AGL_to_unicode = eval $$1;\
	  while (<>) {\
	    s/\#.*//;\
	    next unless my ($$name, $$code) = split /\s+/;\
	    next unless my $$unicode = $$AGL_to_unicode{$$name};\
	    next unless $$unicode ge "0100";\
	    say "0x$$unicode $$name";\
	  }\
	}\
	exit 0;

AGL-text.enc.nam:	$(MAKEFILE_LIST) Slurp.cpanm
	perl -e '${AGL-text.enc.pl}' ${GROFF_FONT}/devps/${TEXT_ENC} > $@

clean::
	rm -f AGL-text.enc.nam

%.TTF:	%.ttf fontforge.pkg AGL-text.enc.nam
	fontforge -lang=ff -c '$(FF_AGL-text.enc)' $< $@
else
FF_AGL=	\
		Open($$1); \
		RenameGlyphs("$(AGL)"); \
		SetFontNames($$2:r); \
		Generate($$2);

%.TTF:	%.ttf fontforge.pkg
	fontforge -lang=ff -c '$(FF_AGL)' $< $@
endif
