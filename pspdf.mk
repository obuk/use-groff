# setup ps/pdf devices to use groff in japanese

include use-groff.mk

VPATH=	${UG}/files/${OS} ${UG}/files

FILES=	${TMP}/gropdf ${TMP}/ps.local ${TMP}/ja.local	\
	${TMP}/man.local ${TMP}/mdoc.local ${TMP}/pdf.local ${TMP}/troffrc.local

LOCAL_BIN?=	/usr/local/bin

PREGROPS?=	${LOCAL_BIN}/pre-grops-ja.plenv
PREGROPDF?=	${LOCAL_BIN}/pre-grops-ja.plenv
PAPERSIZE?=	a4

BUILDFOUNDRIES?=	${GROFF_FONT}/devpdf/util/BuildFoundries

TMP?=	./tmp

ifeq ("$(OS)", "freebsd")
setup::		ghostscript9-agpl-base.pkg gsfonts.pkg perl5.pkg
endif

ifeq ("$(OS)", "ubuntu")
GS_FONTS?=	gsfonts.pkg
setup::		${GS_FONTS}
all::		fix-foundry
fix-foundry:	${GS_FONTS}
	if [ -x ${GROFF_FONT}/devpdf/util/BuildFoundries ]; then \
		sudo ${GROFF_FONT}/devpdf/util/BuildFoundries ${GROFF_FONT}/devpdf 2>foundry.err; \
		if grep -q '^Warning:.* Unable to locate font.*,a010015l.pfb' foundry.err; then \
			sed '/foundry||(gs)/s||&:/usr/share/fonts/type1/gsfonts|' \
				${GROFF_FONT}/devpdf/Foundry  >foundry.new; \
			[ -s foundry.new ]; \
			sudo install -b -m644 foundry.new ${GROFF_FONT}/devpdf/Foundry; \
		fi; \
		sudo ${GROFF_FONT}/devpdf/util/BuildFoundries ${GROFF_FONT}/devpdf 2>foundry.err; \
		if grep -q ^Warning: foundry.err; then false; fi; \
	fi

clean::
	rm -f foundry.new foundry.err
endif

# copy ${FILES} to ${TMP} directory and apply patches.
all::	tmpdir $(FILES)

ifeq ("$(OS)", "ubuntu")
all::	libfile-spec-native-perl.pkg
endif
install::	all
	cd ${TMP}; sudo install -m 644 *.local *.tmac troffrc ${SITE_TMAC}
	cd ${TMP}; sudo install -m 755 gropdf ${GROPDF}

tmpdir:
	rm -rf ${TMP}
	mkdir -p ${TMP}

clean::
	rm -rf ${TMP}

install::	${TMP}/pre-grops-ja.plenv
	sudo install -m 755 $< ${LOCAL_BIN}

${TMP}/pre-grops-ja.plenv:	App-grops-prepro.cpanm $(MAKEFILE_LIST)
	echo "#!/bin/sh\n\
	USER=\$${USER:-vagrant}\n\
	HOME=\$$(getent passwd \$${USER} | cut -d: -f6)\n\
	export PLENV_ROOT=\"\$${HOME}/.plenv\"\n\
	exec \"\$${PLENV_ROOT}/libexec/plenv\" exec pre-grops-ja \"\$$@\"" >$@

# update dev{ps,pdf}/DESC
INSTALL_DESC=	\
	D=${GROFF_FONT}/$$(basename $< | tr . /); \
	diff -c $$D $< || sudo install -m 644 -b $< $$D

install::	update-DESC-devps update-DESC-devpdf

update-DESC-devps:	${TMP}/devps.DESC
	$(INSTALL_DESC)

update-DESC-devpdf:	${TMP}/devpdf.DESC
	$(INSTALL_DESC)

.PHONY:	${TMP}/devps.DESC
${TMP}/devps.DESC:	${GROFF_FONT}/devps/DESC
	(sed -e /^papersize/d -e /^prepro/d $<; \
	 echo papersize ${PAPERSIZE}; \
	 echo prepro ${PREGROPS}; \
	) > $@

.PHONY:	${TMP}/devpdf.DESC
${TMP}/devpdf.DESC:	${GROFF_FONT}/devpdf/DESC
	(sed -e /^papersize/d -e /^prepro/d -e /^postpro/d $<; \
	 echo papersize ${PAPERSIZE}; \
	 echo prepro ${PREGROPDF}; \
	 echo postpro ${GROPDF}; \
	) > $@


# gropdf

GROPDF_HEAD?=	http://git.savannah.gnu.org/cgit/groff.git/plain/src/devices/gropdf/gropdf.pl

GROPDF_CFG=	\
	use strict; \
	my %cfg = (PERL => (scalar <ARGV>) =~ /(\/\S*)/); \
	/^\$$cfg\{(\w+)\}\s*=/ and eval while <ARGV>; \
	$$cfg{VERSION} = $$cfg{GROFF_VERSION}; \
	$$cfg{GROFF_FONT_DIR} = $$cfg{GROFF_FONT_PATH}; \
	s|[@](\w+)[@]|$$cfg{$$1}//$$&|eg, print while <>;

GROPDF?=	${LOCAL_BIN}/gropdf$(shell cat $(abspath gropdf.suffix))

gropdf.suffix:
	date +-%m%d >$@

gropdf.dist:	$(MAKEFILE_LIST)
	curl -Ls ${GROPDF_HEAD} >$@

clean::
	rm -f gropdf.suffix
	rm -f gropdf.dist

${TMP}/gropdf:	gropdf.patch gropdf.dist gropdf.suffix
	cat gropdf.dist | perl -w -e '${GROPDF_CFG}' ${GROFF_BIN}/gropdf >$@
	patch -d ${TMP} <$<

${TMP}/%.patched:	%.patch
	cp ${GROFF_TMAC}/`basename $*` ${TMP}/$*
	patch -d ${TMP} <$<
	cp ${TMP}/$* $@

define merge_local
${TMP}/$(strip $(1)):	$(1)
	if [ ! -f ${SITE_TMAC}/$(strip $(1)).dist ]; then \
	  sudo cp -p ${SITE_TMAC}/$(strip $(1)) ${SITE_TMAC}/$(strip $(1)).dist; \
	fi
	cat ${SITE_TMAC}/$(strip $(1)).dist $$< >$$@
endef

$(eval $(call merge_local, man.local))
$(eval $(call merge_local, mdoc.local))

define add_mso_local
${TMP}/$(strip $(1)):	$(1) $(3)
	if [ -n "$(3)" ]; then \
	  cp $(3) ${TMP}/$(strip $(2)); \
	  ${ADD_MSO_LOCAL} ${TMP}/$(strip $(2)) >${TMP}/$(strip $(2)).tmp; \
	  mv -f ${TMP}/$(strip $(2)).tmp ${TMP}/$(strip $(2)); \
	else \
	  ${ADD_MSO_LOCAL} ${GROFF_TMAC}/$(strip $(2)) >${TMP}/$(strip $(2)); \
	fi
	cp $$< $$@
endef

$(eval $(call add_mso_local, pdf.local, pdf.tmac, ${TMP}/pdf.tmac.patched))
$(eval $(call add_mso_local, troffrc.local, troffrc))
$(eval $(call add_mso_local, %.local, $$*.tmac))


# mdoc
install::	mdoc-ja.UTF-8
	sudo install -m644 mdoc-ja.UTF-8 ${GROFF_TMAC}/mdoc/ja.UTF-8

OPERATING_SYSTEM?=	$(shell uname -sr | sed -E -e 's/-.*//' -e 's/[[:space:]]/\\\\~/g')

mdoc-ja.UTF-8:	mdoc-ja.eucJP groff.pkg
	iconv -f eucJP -t UTF-8 $< | sed '1s/japanese[^;]*/utf-8/' > $@.tmp
	if grep -q '^[.]ds doc-section-name' ${GROFF_TMAC}/mdoc/doc-common; then \
	   perl -i.bak -lpe 's/^(\.\w+\s+)(.*)/$${1}doc-$$2/' $@.tmp; \
	fi;
	echo .ds default-operating-system ${OPERATING_SYSTEM} >> $@.tmp
ifeq ("$(OS)", "ubuntu")
	perl -i.bak -lpe 's/^(\.\w+\s+doc-section-name\s+).*/$${1}名前/' $@.tmp
endif
	preconv < $@.tmp > $@

mdoc-ja.eucJP:	tmac-20030521_2.tar.gz
	tar xzOf $< tmac-20030521_2/mdoc/ja.eucJP >$@

tmac-20030521_2.tar.gz:	$(MAKEFILE_LIST)
	[ -f $@ ] || curl -LOs http://distcache.FreeBSD.org/local-distfiles/hrs/$@

clean::
	rm -f tmac-20030521_2.tar.gz
	rm -f mdoc-ja.eucJP
	rm -f mdoc-ja.UTF-8
	rm -f mdoc-ja.UTF-8.tmp
