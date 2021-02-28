# install groff --prefix=/usr/local

GROFF_PREFIX?=	/usr/local

include use-groff.mk

VPATH=  ${UG}/files/${OS} ${UG}/files

ifeq ("$(OS)", "ubuntu")

setup::	automake.pkg autoconf.pkg libtool.pkg texinfo.pkg bison.pkg pkgconf.pkg \
		libuchardet-dev.pkg libxaw7-dev.pkg
	[ -d groff ] || git clone https://git.savannah.gnu.org/git/groff.git
	cd groff && git reset --hard
	cd groff && git pull;
	cd groff && ./bootstrap && ./configure --prefix=${GROFF_PREFIX}

clean::
	if [ -d groff ]; then \
		$(MAKE) -C groff $@; \
	fi

all::	groff.diff setup
	[ -d groff ]
	cd groff && git reset --hard
	cd groff && patch -p1 <$(abspath $<)
	$(MAKE) -C groff $@

install:: all
	sudo make -C groff $@
	if [ ! -L "${SITE_TMAC}" -o "$$(readlink ${SITE_TMAC})" != "/etc/groff" ]; then \
		sudo mv ${SITE_TMAC} ${SITE_TMAC}.old; \
		sudo ln -s /etc/groff ${SITE_TMAC}; \
	fi
endif
