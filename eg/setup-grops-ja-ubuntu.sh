#!/bin/sh

# setup grops ja ubuntu

set -eu

WORK=${WORK-work}
TRANSFORMS="Italic Bold BoldItalic"

ENV="$(cat <<END
GROFF_FONT=/usr/share/groff/current/font
SITE_FONT=/usr/share/groff/site-font
END
)"

sudo apt-get -y install groff fontforge

fontname () {
    fontforge -lang=ff -c "Open(\"$1\"); Print(\$fontname);" 2>/dev/null
}

sudo apt-get -y install git
[ -d $WORK ] || git clone https://github.com/obuk/using-grops $WORK

cd $WORK

# install mincho and gothic fonts in regular style.
sudo apt-get -y install fonts-ipafont
MINCHO=/usr/share/fonts/*type/*/ipam.ttf
GOTHIC=/usr/share/fonts/*type/*/ipag.ttf
sudo $ENV ./install-font.sh MR $MINCHO
sudo $ENV ./install-font.sh GR $GOTHIC


# generate and install transformed fonts with fontforge.
for font in $MINCHO $GOTHIC; do
    name=$(fontname $font)
    case "$name" in
	*Mincho*) family=M ;;
	*Gothic*) family=G ;;
	*) echo "?family" >&2; exit 1 ;;
    esac
    for subname in $TRANSFORMS; do
	style=$(echo $subname | tr -d a-z)
	if [ ! -f $name-$subname.ttf ]; then
	    ./generate-font.sh -n $subname $style $font
	fi
	sudo $ENV ./install-font.sh $family$style $name-$subname.ttf
    done
done


# For example, install tmac adding Mincho as a special font to Groff's
# Times family.
cp /usr/share/groff/current/tmac/ps.tmac .
patch <ps.tmac.patch
sudo install -m644 ps.tmac ps.local /usr/share/groff/site-tmac
