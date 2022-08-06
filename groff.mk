# install groff --prefix=/usr/local

GROFF_PREFIX?=	/usr/local

include use-groff.mk

VPATH=  ${UG}/files/${OS} ${UG}/files

ifeq ("$(OS)", "ubuntu")

GROFF_GIT?=	https://git.savannah.gnu.org/git/groff.git
#GROFF_GIT?=	https://github.com/t-tk/groff-CJK-font.git
GROFF_DIR?=	$(shell basename $(GROFF_GIT) .git)

# https://ja.wikipedia.org/w/index.php?search=CJK+Compatibility+Ideographs
patch_cjk_compat=	perl -i.bak -lne \
	'next if /^\s*(\{\s*)?"F[9A][0-9A-F]{2}|2F[89A][0-9A-F]{2}",/; print'

all:: automake.pkg autoconf.pkg libtool.pkg texinfo.pkg bison.pkg	\
		pkgconf.pkg libuchardet-dev.pkg libxaw7-dev.pkg
	[ -d $(GROFF_DIR) ] || git clone $(GROFF_GIT) $(GROFF_DIR)
	cd $(GROFF_DIR); \
	git reset --hard; \
	git pull; \
	[ -f ./bootstrap ] && ./bootstrap; \
	./configure --prefix=${GROFF_PREFIX}
	cd $(GROFF_DIR); \
	$(patch_cjk_compat) \
		src/utils/afmtodit/afmtodit.tables \
		src/libs/libgroff/uniuni.cpp
	$(MAKE) -C $(GROFF_DIR) $@

clean::
	-[ -d $(GROFF_DIR) ] && $(MAKE) -C $(GROFF_DIR) $@

install:: all
	sudo make -C $(GROFF_DIR) $@
	if [ ! -L "${SITE_TMAC}" -o "$$(readlink ${SITE_TMAC})" != "/etc/groff" ]; then \
		sudo mv ${SITE_TMAC} ${SITE_TMAC}.old; \
		sudo ln -s /etc/groff ${SITE_TMAC}; \
	fi
endif
