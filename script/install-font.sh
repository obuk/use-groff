#!/bin/sh

set -eu

GROFF_VERSION=$(groff -v |sed -n '/.*version */{s///p;q;}')

case `uname` in
    Linux)
	GROFF_PREFIX=${GROFF_PREFIX:-/usr}
        GROFF_TMAC="${GROFF_TMAC:-$GROFF_PREFIX/share/groff/$GROFF_VERSION/tmac}"
        SITE_TMAC="${SITE_TMAC:-$GROFF_PREFIX/share/groff/site-tmac}"
        GROFF_FONT="${GROFF_FONT:-$GROFF_PREFIX/share/groff/$GROFF_VERSION/font}"
        SITE_FONT="${SITE_FONT:-$GROFF_PREFIX/share/groff/site-font}"
        ;;
    *)
	GROFF_PREFIX=${GROFF_PREFIX:-/usr/local}
        GROFF_TMAC="${GROFF_TMAC:-$GROFF_PREFIX/share/groff/$GROFF_VERSION/tmac}"
        SITE_TMAC="${SITE_TMAC:-$GROFF_PREFIX/share/groff/site-tmac}"
        GROFF_FONT="${GROFF_FONT:-$GROFF_PREFIX/share/groff/$GROFF_VERSION/font}"
        SITE_FONT="${SITE_FONT:-$GROFF_PREFIX/share/groff/site-font}"
        ;;
esac

TYPE42_FONT=${TYPE42_FONT:-$SITE_FONT/devps}

AFMTODIT=${AFMTODIT:-"-s"}
TEXTMAP=${TEXTMAP:-$GROFF_FONT/devps/generate/textmap}
TEXTENC=${TEXTENC:-""}

PDF_ENABLE=${PDF_ENABLE:-"yes"}
FOUNDRY=${FOUNDRY:-""}
EMBED=${EMBED:="*"}

GS_ENABLE=${GS_ENABLE:-"yes"}
if echo "$GS_ENABLE" | grep -iq "yes"; then
    GS_FONTMAP=${GS_FONTMAP:-"$(gs --help | sed -e '1,/^Search path/d' -e '/^[^ ]/d' | \
      tr ': ' '\n' | grep -F '/Resource/Init')/Fontmap"}
    GROFF_FONTMAP=${GROFF_FONTMAP:-$TYPE42_FONT/Fontmap}
    if [ "$GROFF_FONTMAP" = "$GS_FONTMAP" ]; then
	GROFF_FONTMAP=$GROFF_FONTMAP.GROFF
    fi
fi

# also install font as internalname
LONGNAME_ENABLE=${LONGNAME_ENABLE:-"yes"}

usage="usage: $(basename $0) groff-fontname fontfile.{ttf,otf}"

name=${1:?"$usage"}
font=${2:?"$usage"}

font=$(cd $(dirname $font) && echo $(pwd)/$(basename $font)) # abs_path
temp=$(mktemp -d)

(
    if [ -f "$TEXTENC" ]; then
	cp $TEXTENC $temp
	AFMTODIT="$AFMTODIT -e$(basename $TEXTENC)"
    fi
    if [ -f "$TEXTMAP" ]; then
	cp $TEXTMAP $temp
    fi

    cd $temp

    fontname=$(fontforge -lang=ff -c "Open(\"$font\"); Print(\$fontname);")
    fontforge -lang=ff -c "Open(\"$font\");
      RenameGlyphs(\"Adobe Glyph List\");
      Generate(\$fontname + \".afm\");
      Generate(\$fontname + \".t42\");"

    afmtodit="$(set -- $AFMTODIT; if !(test -x "$1" || which $1 2>/dev/null >/dev/null); then echo afmtodit; fi) $AFMTODIT"
    case "$name" in
	*I) afmtodit="$afmtodit -i50" ;;  # use italic correction
	*) afmtodit="$afmtodit -i0 -m" ;; # improve spacing with eqn(1)
    esac
    $afmtodit $fontname.afm $(basename $TEXTMAP) $name

    mkdir -p $TYPE42_FONT
    install -m 644 $fontname.t42 $TYPE42_FONT

    mkdir -p $SITE_FONT/devps
    if [ "$TYPE42_FONT" != "$SITE_FONT/devps" ]; then
	install -m 644 $fontname.afm $TYPE42_FONT
	ln -sf $TYPE42_FONT/$fontname.t42 $SITE_FONT/devps
    fi
    install -m 644 $name $SITE_FONT/devps
    (
	cd $SITE_FONT/devps
	[ -f download ] && awk -F'\t' "\$1 != \"$fontname\" { print }" download
	printf "$fontname\t$fontname.t42\n"
    ) | sort -u > download.devps
    install -m 644 download.devps $SITE_FONT/devps/download
    if echo "$LONGNAME_ENABLE" | grep -iq "yes"; then
        iname=$(grep ^internalname $SITE_FONT/devps/$name | cut -d ' ' -f 2)
        ln -f $SITE_FONT/devps/$name $SITE_FONT/devps/$iname
    fi

    if echo "$PDF_ENABLE" | grep -iq "yes"; then
	mkdir -p $SITE_FONT/devpdf
	ln -sf $SITE_FONT/devps/$name $SITE_FONT/devpdf
	(
	    cd $SITE_FONT/devpdf
	    [ -f download ] && awk -F'\t' "\$2 != \"$fontname\" { print }" download
	    printf "$FOUNDRY\t$fontname\t$EMBED$TYPE42_FONT/$fontname.t42\n"
	) | sort -u > download.devpdf
	install -m 644 download.devpdf $SITE_FONT/devpdf/download
        if echo "$LONGNAME_ENABLE" | grep -iq "yes"; then
            ln -sf $SITE_FONT/devps/$iname $SITE_FONT/devpdf
        fi
    fi

    if echo "$GS_ENABLE" | grep -iq "yes"; then
	cat download.devps | while read fontname fontpath; do
	    fontpath=$(cd $SITE_FONT/devps;
		       if [ -L $fontpath ]; then fontpath=$(readlink $fontpath); fi;
		       cd $(dirname $fontpath);
		       echo $(pwd)/$(basename $fontpath))
	    printf "/$fontname ($fontpath);\n"
	done >Fontmap.GROFF
	install -m 644 Fontmap.GROFF $GROFF_FONTMAP
	(cat $GS_FONTMAP | grep -v "(.*[Gg][Rr][Oo][Ff][Ff].*) \.runlibfile" | \
	     grep -vF "($GROFF_FONTMAP)";
	 echo "($GROFF_FONTMAP) .runlibfile") >Fontmap
	install -m 644 Fontmap $GS_FONTMAP
    fi
)

rm -rf $temp
