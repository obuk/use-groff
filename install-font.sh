#!/bin/sh

set -eu

PATH=/usr/local/bin:$PATH
GROFF_FONT=${GROFF_FONT-/usr/local/share/groff/current/font}
SITE_FONT=${SITE_FONT-/usr/local/share/groff/site-font}
AFMTODIT=${AFMTODIT-"-s"}
TEXTMAP=${TEXTMAP:-$GROFF_FONT/devps/generate/textmap}
TEXTENC=${TEXTENC:-""}

usage="usage: $(basename $0) groff-fontname fontfile.{ttf,otf}"

name=${1:?"$usage"}
font=${2:?"$usage"}

font=$(cd $(dirname $font) && echo $(pwd)/$(basename $font)) # abs_path
temp=$(mktemp -d)

(
    cd $temp

    fontforge -lang=ff -c "Open(\"$font\");
      RenameGlyphs(\"Adobe Glyph List\");
      Generate(\$fontname + \".afm\");
      Generate(\$fontname + \".t42\");"
    fontname=$(basename *.afm .afm)

    if [ -f "$TEXTENC" ]; then
	cp $TEXTENC .
	AFMTODIT="$AFMTODIT -e$(basename $TEXTENC)"
    fi
    if [ -f "$TEXTMAP" ]; then
	cp $TEXTMAP .
    fi
    afmtodit="$(set -- $AFMTODIT; if [ ! -x $1 ]; then echo afmtodit; fi) $AFMTODIT"
    case "$name" in
	*I) afmtodit="$afmtodit -i50" ;;  # use italic correction
	*) afmtodit="$afmtodit -i0 -m" ;; # improve spacing with eqn(1)
    esac
    $afmtodit $fontname.afm $(basename $TEXTMAP) $name

    mkdir -p $SITE_FONT/devps
    (
	cd $SITE_FONT/devps
	[ -f download ] && grep -v "^$fontname[[:space:]]" download
	printf "$fontname\t$fontname.t42\n"
    ) | sort -u > download

    sudo install -m 644 $name $fontname.t42 download \
	    $SITE_FONT/devps
)

rm -rf $temp
