# install fonts to use groff in japanese

include use-groff.mk

REPO?=		source-han-code-jp
CODE?=		SourceHanCode

# override C (experimental)
FAM?=		Code
Code?=		${CODE}${CN}

VPATH?=	source-han-code-jp/Regular \
	source-han-code-jp/Bold

include font-source.mk

HYPHEN-MINUS.PL= \
	my $$hyphen = "00002d.ffffffff.0"; \
	my $$minus = "002212.ffffffff.0"; \
	if (/AltUni2:/ && /$$hyphen/) { \
	  $$_ = join " ", $$_, $$minus; \
	} elsif (/AltUni2:/ && /$$minus/) { \
	  $$_ = join " ", grep !/$$minus/, split /\s+/; \
	  next if /^AltUni2:$$/; \
	} \
	print;

${Code}-$R.sfd:	${Code}-Regular.ttf fontforge.pkg
	fontforge -lang=ff -c '$(FF_SAVE)' $< $@
	perl -i.bak -lne '$(HYPHEN-MINUS.PL)' $@

${Code}-$B.sfd:	${Code}-Bold.ttf fontforge.pkg
	fontforge -lang=ff -c '$(FF_SAVE)' $< $@
	perl -i.bak -lne '$(HYPHEN-MINUS.PL)' $@

source-han-code-jp/Regular/${CODE}${CN}-Regular.otf \
source-han-code-jp/Bold/${CODE}${CN}-Bold.otf:		source-han-code-jp.git afdko.pip
	$(call build-han,${CODE},,,_fs)
