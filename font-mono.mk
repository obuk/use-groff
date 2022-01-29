# install fonts to use groff in japanese

include use-groff.mk

REPO?=		source-han-mono
MONO?=		SourceHanMono

# override C (experimental)
FAM?=		Code
Code?=		${MONO}${CN}

VPATH?=	source-han-mono/Regular/OTC \
	source-han-mono/Bold/OTC

include font-code.mk

FF_USE_HAN?=	\
	Open($$1); \
	CIDFlattenByCMap($$3); \
	Reencode("UnicodeFull",1); \
	SetFontNames($$2:r); \
	$(if $(filter %.sfd,$@),Save($$2),Generate($$2))

FF_USE_HAN_JP?=	\
	Open($$1); \
	CIDChangeSubFont($$4+"-Hangul"); SelectAll(); Clear(); \
	CIDChangeSubFont($$4+"-Italic"); SelectAll(); Clear(); \
	CIDChangeSubFont($$4+"-ItalicCJK"); SelectAll(); Clear(); \
	CIDChangeSubFont($$4+"-ItalicDigits"); SelectAll(); Clear(); \
	CIDFlattenByCMap($$3); \
	Reencode("UnicodeFull", 1); \
	SetFontNames($$2:r); \
	$(if $(filter %.sfd,$@),Save($$2),Generate($$2));

${MONO}${CN}-Regular.ttf:	${MONO}-Regular.otf fontforge.pkg
	fontforge -lang=ff -c '$(FF_USE_HAN_JP)' $< $@ \
		source-han-mono/Uni${MONO}${CN}-UTF32-H ${MONO}-Regular

${MONO}${CN}-Bold.ttf:		${MONO}-Bold.otf fontforge.pkg
	fontforge -lang=ff -c '$(FF_USE_HAN_JP)' $< $@ \
		source-han-mono/Uni${MONO}${CN}-UTF32-H ${MONO}-Bold

source-han-mono/Regular/OTC/${MONO}-Regular.otf \
source-han-mono/Bold/OTC/${MONO}-Bold.otf:		source-han-mono.git afdko.pip
	$(call build-han,${MONO},.OTC.J)
