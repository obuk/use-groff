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

SFDFILES?=	$(foreach fam, ${FAM}, $($(fam))-$R.sfd $($(fam))-$B.sfd \
			$($(fam))-$V.sfd $($(fam))-$(BV).sfd)

all::		$(SFDFILES)

clean::
	rm -f $(SFDFILES)
	rm -f $(patsubst %.sfd,%.SFD,$(SFDFILES))

.PRECIOUS:	$(SFDFILES)

%-$R.sfd:	%-Regular.ttf fontforge.pkg $(PALT)
	fontforge -lang=ff -c '$(FF_SAVE)' $< $@ && \
	bash -l -c 'perl -i.bak $(PALT) -a $(abspath $@)'

%-$B.sfd:	%-Bold.ttf fontforge.pkg $(PALT)
	fontforge -lang=ff -c '$(FF_SAVE)' $< $@ && \
	bash -l -c 'perl -i.bak $(PALT) -a $(abspath $@)'

%-$V.sfd:	%-Regular.ttf fontforge.pkg $(PALT)
	fontforge -lang=ff -c '$(FF_VERT)' $< $@ && \
	bash -l -c 'perl -i.bak $(PALT) -vpal -a $(abspath $@)' && \
	mv -f $@ $(patsubst %.sfd,%.SFD,$@) && \
	fontforge -lang=ff -c '$(FF_VROT)' $(patsubst %.sfd,%.SFD,$@) $@

%-$(BV).sfd:	%-Bold.ttf fontforge.pkg $(PALT)
	fontforge -lang=ff -c '$(FF_VERT)' $< $@ && \
	bash -l -c 'perl -i.bak $(PALT) -vpal -a $(abspath $@)' && \
	mv -f $@ $(patsubst %.sfd,%.SFD,$@) && \
	fontforge -lang=ff -c '$(FF_VROT)' $(patsubst %.sfd,%.SFD,$@) $@
