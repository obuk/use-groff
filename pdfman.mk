include use-groff.mk

ifeq ("$(OS)", "ubuntu")
setup::	nkf.pkg
endif
ifeq ("$(OS)", "freebsd")
setup::	ja-nkf.pkg
endif
all::	setup
	cd pdfman; cpanm --installdeps .

install::
