# install fonts to use groff in japanese

include use-groff.mk

REPO=		sauce-han-fonts
SERIF=		SauceHanSerif
SANS=		SauceHanSans

VPATH=		$(patsubst %,%/${SERIF},${REPO}) $(patsubst %,%/${SANS},${REPO})

setup::	$(patsubst %,%.git,${REPO})

$(patsubst %,%.git,${REPO}):
	[ -d `basename $@ .git` ] || git clone --depth 1 https://github.com/adobe-fonts/$@
	touch $@

veryclean::
	rm -rf ${REPO}
	rm -f $(patsubst %,%.git,${REPO})

FF_BOLD=
include font-common.mk

${REPO}/${SERIF}/$M-Regular.ttf \
${REPO}/${SANS}/$G-Regular.ttf \
${REPO}/${SERIF}/$M-Bold.ttf \
${REPO}/${SANS}/$G-Bold.ttf:	sauce-han-fonts.git

all::	$(foreach fam, ${FAM}, $($(fam))-$R.sfd $($(fam))-$B.sfd)

clean::
	rm -f $(foreach fam, ${FAM}, $($(fam))-$R.sfd $($(fam))-$B.sfd)

%-$R.sfd:	%-Regular.ttf fontforge.pkg
	fontforge -lang=ff -c '$(FF_SAVE)' $< $@

%-$B.sfd:	%-Bold.ttf fontforge.pkg
	fontforge -lang=ff -c '$(FF_SAVE)' $< $@
