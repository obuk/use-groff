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

FONT_FEATURE?=	palt

ifneq "$(filter palt,$(FONT_FEATURE))" ""
%-$R.sfd:	%-Regular.ttf fontforge.pkg ./script/palt.pl Clone.cpanm
	fontforge -lang=ff -c '$(FF_SAVE)' $< a.sfd
	bash -l -c './script/palt.pl a.sfd' >$@ && rm -f a.sfd

%-$B.sfd:	%-Bold.ttf fontforge.pkg ./script/palt.pl Clone.cpanm
	fontforge -lang=ff -c '$(FF_SAVE)' $< a.sfd
	bash -l -c './script/palt.pl a.sfd' >$@ && rm -f a.sfd
else
%-$R.sfd:	%-Regular.ttf fontforge.pkg
	fontforge -lang=ff -c '$(FF_SAVE)' $< $@

%-$B.sfd:	%-Bold.ttf fontforge.pkg
	fontforge -lang=ff -c '$(FF_SAVE)' $< $@
endif

%-$V.sfd:	%-Regular.ttf fontforge.pkg $(MAKEFILE_LIST)
	fontforge -lang=ff -c '$(FF_VERTICAL_WRITING); Save($$2)' $< $@

%-$(BV).sfd:	%-Bold.ttf fontforge.pkg $(MAKEFILE_LIST)
	fontforge -lang=ff -c '$(FF_VERTICAL_WRITING); Save($$2)' $< $@

clean::
	rm -f $(foreach fam, ${FAM}, $($(fam))-Regular.ttf $($(fam))-Bold.ttf)
