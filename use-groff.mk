# use-groff
ifndef _use_groff
_use_groff:=	1

# default
all::
setup::		groff.pkg git.pkg

UG?=		.
ADD_MSO_LOCAL?=	${UG}/script/add-mso-local.pl
INSTALL_PLENV?=	${UG}/script/install-plenv.sh
INSTALL_FONT?=	${UG}/script/install-font.sh
GENERATE_FONT?=	${UG}/script/generate-font.sh
MAKE_TEXTMAP?=	${UG}/script/make-textmap.pl
FIX_FOUNDARY?=	${UG}/script/fix-foundary.pl

OS:=	$(shell \
	if [ -f /etc/lsb-release ]; then echo ubuntu; \
	else uname; \
	fi | tr A-Z a-z)

ifeq "$(filter ${OS}, freebsd ubuntu)" ""
$(error OS (${OS}) not supported)
endif

ifeq ("$(OS)", "freebsd")
GROFF_PREFIX?=	/usr/local
endif
ifeq ("$(OS)", "ubuntu")
#GROFF_PREFIX?=	/usr
GROFF_PREFIX?=	$(shell which groff |sed 's/\/bin\/groff//')
endif

# groff

GROFF_BIN?=	${GROFF_PREFIX}/bin
GROFF_SHARE?=	${GROFF_PREFIX}/share/groff
GROFF_TMAC?=	${GROFF_SHARE}/current/tmac
GROFF_FONT?=	${GROFF_SHARE}/current/font
SITE_TMAC?=	${GROFF_SHARE}/site-tmac
SITE_FONT?=	${GROFF_SHARE}/site-font
GROFF_TEXTMAP?=	${GROFF_FONT}/devps/generate/textmap
AFMTODIT?=	perl ${GROFF_BIN}/afmtodit -s


# perl

PERL_VERSION?=	5.30.2

.SUFFIXES:	.stamp

plenv.stamp:
	bash -l -c 'env PERL_VERSION=${PERL_VERSION} ${INSTALL_PLENV}'
	@touch $@

#	bash -l -c 'type $* >/dev/null 2>&1 || ${INSTALL_PLENV}'

cpanm.stamp:	plenv.stamp
	bash -l -c 'plenv install-cpanm'
	@touch $@

#	bash -l -c 'type $* >/dev/null 2>&1 || plenv install-cpanm'

Font-TTF?=		https://github.com/obuk/font-ttf.git
Pod-Man-TMAC?=		https://github.com/obuk/Pod-Man-TMAC.git
Pod-Perldoc-ToNroff4?=	https://github.com/obuk/Pod-Perldoc-ToNroff4.git

%.cpanm: cpanm.stamp
	@echo cpanm $(basename $@)
	@m=$(shell echo $* |sed s/-/::/g); \
	bash -l -c "cpanm $(or $($*), $$m)"
	@touch $@

#	bash -l -c "perl -M$$m -e '' 2>/dev/null || cpanm $(or $($*), $$m)"

clean::
	rm -f plenv.stamp
	rm -f cpanm.stamp
	rm -f *.cpanm

# pkg

.PRECIOUS:	pkg.stamp
ifeq ("${OS}", "freebsd")
%.pkg:	pkg.stamp
	sudo pkg install -y $*
	@touch $@

pkg.stamp:
	[ -f $@ ] || sudo env ASSUME_ALWAYS_YES=yes pkg update
	touch $@
endif

ifeq ("${OS}", "ubuntu")
%.pkg:	pkg.stamp
	sudo apt-get install -y $*
	@touch $@

pkg.stamp:
	[ ! -f $@ ] || sudo apt-get update
	@if [ -f /var/run/reboot-required ]; then \
		echo "# $(MAKE) -f use-groff.mk apt-upgrade" >&2; \
		echo "# vagrant reload" >&2; \
	fi
	@[ ! -f /var/run/reboot-required ]
	@touch $@

export DEBIAN_FRONTEND=noninteractive

APT_GET_QY?=	apt-get -q -y \
		-o Dpkg::Options::="--force-confold" \
		--allow-unauthenticated \
		--allow-downgrades \
		--allow-remove-essential \
		--allow-change-held-packages

apt-upgrade:
	if sudo apt-get update; then \
		if sudo -E ${APT_GET_QY} upgrade; then \
			sudo -E ${APT_GET_QY} dist-upgrade; \
		fi \
	fi
endif

clean::
	rm -f pkg.stamp
	rm -f *.pkg

endif # _use_groff
