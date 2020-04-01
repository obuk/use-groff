# output ps/pdf with perldoc

include use-groff.mk

VPATH=	${UG}/files/${OS} ${UG}/files

setup::

all::	Pod-Man-TMAC.cpanm Pod-Perldoc-ToNroff4.cpanm \
	Pod-PerldocJp.cpanm POD2-Base.cpanm

install::	pod2manja.tmac
	sudo cp pod2manja.tmac ${SITE_TMAC}

pod2manja.tmac:
	[ -f $@ ] || curl -LOs https://raw.githubusercontent.com/obuk/Pod-Man-TMAC/master/eg/$@

clean::
	rm -f pod2manja.tmac

LOCATE_DB?=	/var/lib/mlocate/mlocate.db

install::	perldoc.sh
	[ -f $(LOCATE_DB) ] || sudo updatedb
	sudo install -m755 $< /usr/local/bin


ifeq ("$(OS)", "ubuntu")
Pod-PerldocJp.cpanm: libssl-dev.pkg zlib1g-dev.pkg
endif
ifeq ("$(OS)", "freebsd")
Pod-PerldocJp.cpanm: openssl.pkg
endif
