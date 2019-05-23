#!/bin/sh

# setup grops ja ubuntu

set -eu

WORK=${WORK-work}
TRANSFORMS="Italic Bold BoldItalic"

GROFF_FONT=/usr/share/groff/current/font
GROFF_TMAC=/usr/share/groff/current/tmac
SITE_FONT=/usr/share/groff/site-font
SITE_TMAC=/usr/share/groff/site-tmac

install_font () {
    sudo env GROFF_FONT=$GROFF_FONT SITE_FONT=$SITE_FONT \
	 ./install-font.sh $*
}

sudo apt-get -y install groff

sudo apt-get -y install git
[ -d $WORK ] || git clone https://github.com/obuk/using-grops $WORK

cd $WORK

# Sauce Han Japanese TrueType fonts converted from Source Han Sans.
[ -d sauce-han-fonts ] || \
    git clone https://github.com/3846masa/sauce-han-fonts.git

MINCHO=sauce-han-fonts/SauceHanSerif/SauceHanSerifJP
install_font MR $MINCHO-Regular.ttf
install_font MB $MINCHO-Bold.ttf

GOTHIC=sauce-han-fonts/SauceHanSans/SauceHanSansJP
install_font GR $GOTHIC-Regular.ttf
install_font GB $GOTHIC-Bold.ttf

cp $GROFF_TMAC/ps.tmac .
patch <ps.tmac.patch
sudo install -m644 ps.tmac ./eg/ps.local $SITE_TMAC

# install pre-grops.pl to support japanese justification
sudo apt-get -y install libyaml-syck-perl
sudo install eg/pre-grops.pl /usr/local/bin/
sudo install eg/pre-grops.rc /etc/groff/

(sed /^prepro/d $GROFF_FONT/devps/DESC; echo prepro pre-grops.pl) >DESC
sudo install 644 DESC $GROFF_FONT/devps/DESC
