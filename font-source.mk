# install fonts to use groff in japanese

include use-groff.mk

REPO?=		source-han-serif \
		source-han-sans

SERIF?=		SourceHanSerif
SANS?=		SourceHanSans

FAM?=		M G

setup::	$(patsubst %,%.git,${REPO})

$(patsubst %,%.git,${REPO}):
	[ -d `basename $@ .git` ] || git clone --depth 1 https://github.com/adobe-fonts/$@
	touch $@

veryclean::
	rm -rf ${REPO}
	rm -f $(patsubst %,%.git,${REPO})

VPATH?=	source-han-sans/Regular \
	source-han-sans/Bold \
	source-han-serif/Masters/Regular \
	source-han-serif/Masters/Bold

FF_BOLD=
include font-common.mk

all::	$(foreach fam, ${FAM}, $($(fam))-$R.sfd $($(fam))-$B.sfd)

clean::
	rm -f $(foreach fam, ${FAM}, $($(fam))-$R.sfd $($(fam))-$B.sfd)

%-$R.sfd:	%-Regular.ttf fontforge.pkg
	fontforge -lang=ff -c '$(FF_SAVE)' $< $@

%-$B.sfd:	%-Bold.ttf fontforge.pkg
	fontforge -lang=ff -c '$(FF_SAVE)' $< $@

clean::
	rm -f $(foreach fam, ${FAM}, $($(fam))-Regular.ttf $($(fam))-Bold.ttf)

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

%.pip:	python3.pkg python3-pip.pkg
	sudo pip install $*
	touch $@

clean::
	rm -f *.pip
