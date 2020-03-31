# install groff --prefix=/usr/local

include use-groff.mk

ifeq ("$(OS)", "ubuntu")

GROFF_PREFIX=	/usr/local

setup::	autoconf.pkg libtool.pkg texinfo.pkg bison.pkg pkgconf.pkg \
		libuchardet-dev.pkg libxaw7-dev.pkg
	[ -d groff ] || git clone https://git.savannah.gnu.org/git/groff.git
	cd groff; ./bootstrap; ./configure --prefix=${GROFF_PREFIX}

all clean::
	[ -d groff ] && $(MAKE) -C groff $@

install:: all
	sudo make -C groff $@
	env GROFF_PREFIX=${GROFF_PREFIX} $(MAKE) -f pspdf.mk \
		tmpdir update-DESC-devps update-DESC-devpdf
	@echo
	@echo to run new groff sharing site-font and site-tmac:
	@echo env GROFF_TMAC_PATH=/etc/groff GROFF_FONT_PATH=/usr/share/groff/site-font groff ...
	@echo
	@echo to run groff package installed with apt-get:
	@echo env GROFF_BIN_PATH=/usr/bin groff ...
endif
