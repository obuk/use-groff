#!/bin/bash -e

PROGNAME=${0##*/}
# defaults
OSUFFIX_DEFAULT="pfb"
FONTFORGE_DEFAULT="-quiet -lang=ff"
PYFTSUBSET_DEFAULT="--no-subset-tables+=FFTM"
VERBOSE="n"
usage () {
    cat <<EOF
usage: $PROGNAME [-options] input
  options:
    -g glyphs              # or psnames; e.g. one,two,three or /one/two/three
    -o output              # filename; the suffix indicates format (default: .$OSUFFIX_DEFAULT)
    -f fontforge_options   # default: $FONTFORGE_DEFAULT
    -s pyftsubset_options  # default: $PYFTSUBSET_DEFAULT
    -v                     # verbose
EOF
    exit 1
}
#
OPTIONS=$(getopt g:o:f:s:vh "$@")
set -- $OPTIONS
while [ $# -gt 0 ]; do
    case $1 in
        -o) OUTPUT=$2; shift;;
        -g) GLYPHS="$GLYPHS $2"; shift;;
        -f) FONTFORGE_OPTIONS="$FONTFORGE_OPTIONS $2"; shift;;
        -s) PYFTSUBSET_OPTIONS="$PYFTSUBSET_OPTIONS $2"; shift;;
        -v) VERBOSE="y";;
        -h) usage;;
        --) shift; break;;
    esac
    shift
done
INPUT=$1
[ -z "$INPUT" ] && usage

FONTFORGE_OPTIONS="${FONTFORGE_OPTIONS:-$FONTFORGE_DEFAULT}"
PYFTSUBSET_OPTIONS="${PYFTSUBSET_OPTIONS:-$PYFTSUBSET_DEFAULT}"

run () {
    local PROGRAM="$1"; shift
    local OPTIONS="$(eval echo \$$(echo $PROGRAM |tr '[:lower:]' '[:upper:]')_OPTIONS)"
    [ "$VERBOSE" != "n" ] && echo \# $PROGRAM $OPTIONS $@ >&2
    $PROGRAM $OPTIONS "$@"
}

TMP=$(mktemp -d)
cleanup () {
    if [ -n "$TMP" ]; then
	rm -f $TMP/*
	rmdir $TMP
    fi
}
trap 'cleanup; exit 1' 1 2 3 15

BASENAME=${INPUT##*/}
case $BASENAME in
    *.[oOtT][tT][fF])
        SUFFIX=${BASENAME##*.}
        FONTNAME=${BASENAME%.*}
        SINPUT=$INPUT
        ;;
    *.*)
        BASENAME=${BASENAME%.*}
        ;;&
    *)
        SUFFIX=ttf
        SINPUT=$TMP/$BASENAME.$SUFFIX
        run fontforge -c 'Open($1); Generate($2)' $INPUT $SINPUT
        FONTNAME=$BASENAME
        ;;
esac

SFONTNAME=SUBSET-$FONTNAME

GLYPHS="$(echo $GLYPHS |sed -e 's/ /,/g' -e 's/\//,/g' -e 's/,,,*/,/g' -e 's/^,//')"
if [ -z "$GLYPHS" ]; then
    SUBSET=$SINPUT
else
    SUBSET=$TMP/$SFONTNAME.$SUFFIX
    run pyftsubset --output-file=$SUBSET --glyphs=$GLYPHS $SINPUT
fi

OBASENAME=${OUTPUT##*/}
case $OBASENAME in
    *.*) OSUFFIX="${OSUFFIX:-${OBASENAME##*.}}";;
esac
OSUFFIX="${OSUFFIX:-$OSUFFIX_DEFAULT}"
OSUBSET=$TMP/$SFONTNAME.$OSUFFIX
run fontforge -c 'Open($1); Generate($2)' $SUBSET $OSUBSET

if [ -z "$OUTPUT" -o "$OUTPUT" = "-" ]; then
    [ ! -t 1 ] && run cat $OSUBSET
else
    run cp $OSUBSET $OUTPUT
fi  
cleanup
exit 0
