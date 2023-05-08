# install fonts to use groff in japanese

include use-groff.mk

REPO=		sauce-han-fonts
SERIF=		SauceHanSerif
SANS=		SauceHanSans

FAM?=		M G

STY?=		R I B BI V BV

V?=		V
BV?=		BV

VPATH=		$(patsubst %,%/${SERIF},${REPO}) $(patsubst %,%/${SANS},${REPO})

setup::	$(patsubst %,%.git,${REPO})

$(patsubst %,%.git,${REPO}):
	[ -d `basename $@ .git` ] || git clone --depth 1 https://github.com/3846masa/$@
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


all::	$(foreach fam, ${FAM}, $($(fam))-$R.sfd $($(fam))-$B.sfd \
		$($(fam))-$V.sfd $($(fam))-$(BV).sfd)

clean::
	rm -f $(foreach fam, ${FAM}, $($(fam))-$R.sfd $($(fam))-$B.sfd \
		$($(fam))-$V.sfd $($(fam))-$(BV).sfd)

FF_VERTICAL_WRITING=	\
	Open($$1); \
	SelectAll(); \
	ApplySubstitution("*","*","vrt2"); \
	ApplySubstitution("*","*","vert"); \
	Select(0u0000, 0u2fff); \
	SelectInvert(); \
	Rotate(90, 512, 360); \
	AddExtrema(); \
	RoundToInt();

FF_PALT=	\
	Open($$1); \
	SelectAll(); \
	ApplySubstitution("*","*","palt");

%-$R.sfd:	%-Regular.ttf fontforge.pkg
	fontforge -lang=ff -c '$(FF_PALT); Save($$2)' $< $@

%-$B.sfd:	%-Bold.ttf fontforge.pkg
	fontforge -lang=ff -c '$(FF_PALT); Save($$2)' $< $@

%-$V.sfd:	%-Regular.ttf fontforge.pkg $(MAKEFILE_LIST)
	fontforge -lang=ff -c '$(FF_VERTICAL_WRITING); Save($$2)' $< $@

%-$(BV).sfd:	%-Bold.ttf fontforge.pkg $(MAKEFILE_LIST)
	fontforge -lang=ff -c '$(FF_VERTICAL_WRITING); Save($$2)' $< $@

clean::
	rm -f $(foreach fam, ${FAM}, \
		$($(fam))-$R.sfd $($(fam))-$R.SFD \
		$($(fam))-$B.sfd $($(fam))-$B.SFD)
