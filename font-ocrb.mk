# install fonts to use groff in japanese

include use-groff.mk

FAM?=		OCRB
STY?=

include font-common.mk

OCRB.sfd:	OCRB_aizu_1_1.sfd
	sed '/EndChars/i\
StartChar: space\
Encoding: 32 32 32\
Width: 616\
Flags: W\
EndChar' $< >$@

OCRB_aizu_1_1.sfd:
	[ -s $@ ] || curl -L -O https://www.city.aizuwakamatsu.fukushima.jp/_files/00155182/$@

clean::
	rm -f OCRB.afm OCRB.pfa
	rm -f OCRB_aizu_1_1.sfd
	rm -f OCRB.sfd
