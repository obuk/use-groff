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
install::	install-$(1)

install-$(1):	$(1) $(1).t42
	sudo install -m 644 $(1).t42 ${TYPE42_FONT}
	sudo install -m 644 $(1) ${SITE_FONT}/devps
	sudo ln -sf ${SITE_FONT}/devps/$(1) ${SITE_FONT}/devpdf/$(1)

download.devps::	$(1) $(1).t42
	printf "$(1)\t$(1).t42\n" >> $$@

download.devpdf::	$(1) $(1).t42
	printf "${FOUNDRY}\t$(1)\t${EMBED}${TYPE42_FONT}/$(1).t42\n" >> $$@

# afmtodit option: see /usr/share/groff/current/font/devps/generate/Makefile

$(1):	$(1).afm $(1).t42 $(1).textmap fontforge.pkg
	echo ${AFMTODIT} \
	`case $(1) in \
	 *Mono$(CN)-*|*Code$(CN)-*) echo "\-n";; \
	 esac` \
	`case $(1) in \
	 *$(CN)-$(I)|*$(CN)-$(BI)) echo "\-i50";; \
	 *) echo "\-i0 -m";; \
	 esac` \
	`if [ -n "$(V)" -o -n "$(BV)" ]; then \
	   case $(1) in \
	   *$(CN)-$(V)|*$(CN)-$(BV)) echo "\-n";; \
	   esac; \
	fi` \
	$(1).afm $(1).textmap $(1) | sh -x

clean::
	rm -f $(1)*
endef

define install_font_alias
install::	install-$(2)

install-$(2):	install-$(1)
	sed 's/^name .*/name $(2)/' ${SITE_FONT}/devps/$(1) >/tmp/$(2)
	sudo install -m 644 /tmp/$(2) ${SITE_FONT}/devps/
	sudo ln -sf ${SITE_FONT}/devps/$(2) ${SITE_FONT}/devpdf/$(2)

clean::
	rm -f /tmp/$(2)
endef

install::	download.devps
	for f in $< ${SITE_FONT}/devps/download; do \
	  [ -f $$f ] && cat $$f; \
	done | sort -u >/tmp/download
	sudo install -m 644 /tmp/download ${SITE_FONT}/devps

install::	download.devpdf
	for f in $< ${SITE_FONT}/devpdf/download; do \
	  [ -f $$f ] && cat $$f; \
	done | sort -u >/tmp/download
	sudo install -m 644 /tmp/download ${SITE_FONT}/devpdf

ifeq "${STY}" ""
$(foreach fam,${FAM}, \
  $(eval $(call install_font,$(or $($(fam)),$(fam)))) \
)
else
$(foreach fam, ${FAM}, $(foreach sty, ${STY}, \
  $(eval $(call install_font,$(or $($(fam)),$(fam))-$($(sty)))) \
  $(eval $(call install_font_alias,$(or $($(fam)),$(fam))-$($(sty)),$(fam)$(sty))) \
  $(eval $(call install_font_alias,$(or $($(fam)),$(fam))-$($(sty)),$(or $($(fam)),$(fam))$($(sty)))) \
))
endif

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
	 cat $< | while read fontname fontfile; do \
	   if [ "${TYPE42_FONT}" != "$(GS_FONTDIR)" ]; then \
	     sudo ln -sf ${TYPE42_FONT}/$$fontfile $(GS_FONTDIR); \
	   fi; \
	   printf "/$$fontname ($$fontfile);\n"; \
	 done) |sort -u >Fontmap
	sudo install -b -m 644 Fontmap $(GS_FONTDIR)
endif

SYSMAP=	$(shell	temp=`mktemp`; \
		(echo "print-textmap:"; \
		echo "\t@basename \$$(TEXTMAP)"; \
		echo include $(GROFF_FONT)/devps/generate/Makefile; \
		) >$$temp; $(MAKE) -s -f $$temp; rm $$temp)

MAKE_TEXTMAP_TEXTMAP?=	env \
		GROFF_BIN_PATH=${GROFF_BIN} \
		GROFF_FONT_PATH=${GROFF_FONT} \
		${MAKE_TEXTMAP} $(or ${TEXTMAP_LOCAL}, $(SYSMAP))

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

FF_SAVE=	\
		Open($$1); \
		Save($$2);

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

FF_RENAME?=	\
		Open($$1); \
		LoadNamelist("ff_rename.nam"); \
		RenameGlyphs("ff_rename"); \
		SetFontNames($$2:r); \
		Generate($$2);

ff_rename.pl?=\
	use strict;\
	use warnings;\
	use feature "say";\
	sub slurp { \
	  local($$/, @ARGV) = (wantarray ? $$/ : undef, @_); \
	  return <ARGV>; \
	} \
	my $$afmtodit = slurp "${GROFF_BIN}/afmtodit";\
	say "Based: ${AGL}" if "${AGL}";\
	if ($$afmtodit =~ /%AGL_to_unicode\s*=\s*(\(.*?\))\s*;/s) {\
	  my %AGL_to_unicode = eval $$1;\
	  my %seen;\
	  while (<STDIN>) {\
	    chop;\
	    next unless !$$seen{$$_}++;\
	    next unless my $$unicode = $$AGL_to_unicode{$$_};\
	    say "0x$$unicode $$_";\
	  }\
	}\
	exit 0;

ff_rename.nam:	$(MAKEFILE_LIST)
	echo $(FF_RENAME_LIST) | tr ' ' '\n' | perl -e '${ff_rename.pl}' > $@

FF_RENAME_LIST+=	space

ifneq "${TEXT_ENC}" ""
FF_RENAME_LIST+=	$(shell perl -lae 'next unless !/^\#/ && @F == 2; print $$F[0]' \
				${GROFF_FONT}/devps/${TEXT_ENC})
endif

clean::
	rm -f ff_rename.nam

%.TTF:	%.ttf fontforge.pkg ff_rename.nam
	fontforge -lang=ff -c '$(FF_RENAME)' $< $@

%.ttf:	%.sfd fontforge.pkg $(MAKEFILE_LIST)
	./script/unaltuni2.pl $(patsubst %, -g %, $(FF_RENAME_LIST)) $< >a.sfd
	fontforge -lang=ff -c '$(FF_GENERATE)' a.sfd $@
	rm a.sfd


URI_CIDMAP?=	https://raw.githubusercontent.com/fontforge/fontforge/master/contrib/cidmap

%.cidmap:
	[ -f $@ ] || curl -O $(URI_CIDMAP)/$@

install-fontforge-cidmap:	Adobe-CNS1-6.cidmap Adobe-GB1-5.cidmap \
		Adobe-Identity-0.cidmap \
		Adobe-Japan1-5.cidmap \
		Adobe-Japan1-6.cidmap \
		Adobe-Japan1-7.cidmap \
		Adobe-Japan2-0.cidmap \
		Adobe-Korea1-2.cidmap
	sudo cp $^ /usr/share/fontforge/
