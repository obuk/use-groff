# install fonts to use groff in japanese

include use-groff.mk

REPO=		source-han-serif \
		source-han-sans \
		source-han-mono \
		source-han-code-jp

SERIF=		SourceHanSerif
SANS=		SourceHanSans
MONO=		SourceHanMono
CODE=		SourceHanCode

# override C (experimental)
FAM?=		M G Code
#Code?=		${MONO}${CN}
Code?=		${CODE}${CN}

setup::	$(patsubst %,%.git,${REPO})

$(patsubst %,%.git,${REPO}):
	[ -d `basename $@ .git` ] || git clone --depth 1 https://github.com/adobe-fonts/$@
	touch $@

veryclean::
	rm -rf ${REPO}
	rm -f $(patsubst %,%.git,${REPO})

VPATH=	source-han-sans/Regular \
	source-han-sans/Bold \
	source-han-serif/Masters/Regular \
	source-han-serif/Masters/Bold \
	source-han-mono/Regular/OTC \
	source-han-mono/Bold/OTC \
	source-han-code-jp/Regular \
	source-han-code-jp/Bold

FF_BOLD=
include font-common.mk

all::	$(foreach fam, ${FAM}, $($(fam))-$R.sfd $($(fam))-$B.sfd)

clean::
	rm -f $(foreach fam, ${FAM}, $($(fam))-$R.sfd $($(fam))-$B.sfd)

%-$R.sfd:	%-Regular.ttf fontforge.pkg
	fontforge -lang=ff -c '$(FF_SAVE)' $< $@

%-$B.sfd:	%-Bold.ttf fontforge.pkg
	fontforge -lang=ff -c '$(FF_SAVE)' $< $@

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

#all::	$(foreach fam, ${FAM}, $($(fam))-Regular.ttf $($(fam))-Bold.ttf)

clean::
	rm -f $(foreach fam, ${FAM}, $($(fam))-Regular.ttf $($(fam))-Bold.ttf)

${MONO}${CN}-Regular.ttf:	${MONO}-Regular.otf fontforge.pkg
	fontforge -lang=ff -c '$(FF_USE_HAN_JP)' $< $@ \
		source-han-mono/Uni${MONO}${CN}-UTF32-H ${MONO}-Regular

${MONO}${CN}-Bold.ttf:		${MONO}-Bold.otf fontforge.pkg
	fontforge -lang=ff -c '$(FF_USE_HAN_JP)' $< $@ \
		source-han-mono/Uni${MONO}${CN}-UTF32-H ${MONO}-Bold

%.ttf:	%.otf afdko.pip
	otf2ttf -o $@ $<


build-han=\
	cd `dirname $@`; \
	for d in .. ../..; \
	do if [ -f $$d/COMMANDS.txt -o -f $$d/commands.sh ]; then top=$$d; break; fi; done; \
	makeotf -f cidfont$4.ps$2 \
		-omitMacNames \
		-ff features$2 \
		-fi cidfontinfo$2 \
		-mf $$top/FontMenuNameDB$3 \
		-r -nS -cs 1 \
		-ch $$top/Uni$1${CN}-UTF32-H \
		-ci $$top/$1_${CN}_sequences.txt; \
	tx -cff +S -no_futile cidfont$4.ps$2 CFF$2; \
	sfntedit -a CFF=CFF$2 `basename $@`

source-han-sans/Regular/${SANS}${CN}-Regular.otf \
source-han-sans/Bold/${SANS}${CN}-Bold.otf:		source-han-sans.git afdko.pip
	$(call build-han,${SANS},.${CN},.SUBSET)

source-han-serif/Masters/Regular/${SERIF}${CN}-Regular.otf \
source-han-serif/Masters/Bold/${SERIF}${CN}-Bold.otf:	source-han-serif.git afdko.pip
	$(call build-han,${SERIF},.${CN},.SUBSET)

source-han-mono/Regular/OTC/${MONO}-Regular.otf \
source-han-mono/Bold/OTC/${MONO}-Bold.otf:		source-han-mono.git afdko.pip
	$(call build-han,${MONO},.OTC.J)

source-han-code-jp/Regular/${CODE}${CN}-Regular.otf \
source-han-code-jp/Bold/${CODE}${CN}-Bold.otf:		source-han-code-jp.git afdko.pip
	$(call build-han,${CODE},,,_fs)

%.pip:	python3.pkg python3-pip.pkg
	sudo pip install $*
	touch $@

clean::
	rm -f *.pip
