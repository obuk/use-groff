include use-groff.mk

VPATH=	${UG}/files/${OS} ${UG}/files

setup::
install::	all

ifeq ("$(OS)", "ubuntu")
install::	manpages-ja.pkg
endif

ifeq ("$(OS)", "freebsd")
JAMANDOC_URL?=		ftp://ftp.koganemaru.co.jp/pub/jman11/ja-man-doc-11.3.20190716.amd64.txz
JAMANDOC_FILE:=		$(shell basename ${JAMANDOC_URL})
JAMANDOC_CHARSET?=	eucJP
install::	${JAMANDOC_FILE}
	sudo pkg add -q -M -f $<
	[ -d /usr/share/man/ja.${JAMANDOC_CHARSET} ] || \
		sudo ln -sf ja /usr/share/man/ja.${JAMANDOC_CHARSET}
	echo ${JAMANDOC_CHARSET} >dot.charset
	sudo install -m 644 dot.charset /usr/share/man/ja/.charset
	rm -f dot.charset

${JAMANDOC_FILE}:	$(MAKEFILE_LIST)
	[ -f $@ ] || fetch ${JAMANDOC_URL}

clean::
	rm -f ${JAMANDOC_FILE}
	rm -f dot.charset

install::	man.sh
	sudo install -b -m755 $< /usr/bin/man

install::	man.conf ja-nkf.pkg
	sudo install -b -m644 $< /etc

install::
	grep -Fq 'export LC_CTYPE=ja_JP.UTF-8' ~/.profile || \
		echo export LC_CTYPE=ja_JP.UTF-8 >>~/.profile
endif
