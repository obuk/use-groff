include use-groff.mk

TMP?=	./tmp

GROFF_GIT?=	http://git.savannah.gnu.org/cgit/groff.git
GROPDF_HEAD?=	${GROFF_GIT}/plain/src/devices/gropdf/gropdf.pl
GROPDF_URL?=	${GROPDF_HEAD}?h=deri-gropdf-ng

GROPDF_CFG=	\
	use strict; \
	my %cfg = (PERL => (scalar <ARGV>) =~ /(\/\S*)/); \
	/^\$$cfg\{(\w+)\}\s*=/ and eval while <ARGV>; \
	$$cfg{VERSION} = $$cfg{GROFF_VERSION}; \
	$$cfg{GROFF_FONT_DIR} = $$cfg{GROFF_FONT_PATH}; \
	s|[@](\w+)[@]|$$cfg{$$1}//$$&|eg, print while <>;

NGROPDF?=	deri-gropdf-ng
LOCAL_BIN?=	/usr/local/bin

all::	${NGROPDF}

install::	install-${NGROPDF} install-${NGROPDF}-DESC

install-${NGROPDF}:	${NGROPDF}
	sudo install -m 755 $< ${LOCAL_BIN}/${NGROPDF}

update_postpro_pl= \
	while (<>) { \
		s/^/\x23/ if /^postpro/; \
		print; \
	} \
	print "postpro ${LOCAL_BIN}/${NGROPDF}\n";

install-${NGROPDF}-DESC:	${GROFF_FONT}/devpdf/DESC
	(sed -e /^postpro/s/^/#/ $<; echo postpro ${LOCAL_BIN}/${NGROPDF}) \
	> /tmp/${NGROPDF}-DESC.tmp
	sudo install -b -m 644 /tmp/${NGROPDF}-DESC.tmp $<
	rm -f /tmp/${NGROPDF}-DESC.tmp

${NGROPDF}:	${NGROPDF}.dist
	cat $< | perl -w -e '${GROPDF_CFG}' ${GROFF_BIN}/gropdf >$@

${NGROPDF}.dist:	$(MAKEFILE_LIST)
	curl -Ls ${GROPDF_URL} >$@

clean::
	rm -f ${NGROPDF}.dist
