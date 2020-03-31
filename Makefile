# setup ps/pdf devices to use groff in japanese
#
# usage:
#	make clean
#	make [all]
#	make install

include use-groff.mk

all::	setup

install:: all

setup all install clean::
	$(MAKE) -f pspdf.mk $@
	$(MAKE) -f font.mk $@
	$(MAKE) -f ja-man.mk $@
	$(MAKE) -f perldoc.mk $@
clean::
	$(MAKE) -f sample.mk $@
