#!/bin/sh

set -eu

PATH=/usr/local/bin:$PATH

usage="usage: $(basename $0) [-av] [-s size] [-t .ext] style fontfile
  style: R - Roman, I - Italic, B - Bold, BI - BoldItalic"

while getopts bis:t: OPT
do
    case $OPT in
        s) size=$OPTARG ;;
        t) type=$OPTARG ;;
	*) usage; exit 2 ;;
    esac
done
size=${size-1024}
type=${type-.ttf}
shift $((OPTIND - 1))
[ $# -lt 2 ] && usage && exit 2
style="$1"
font="$2"
subname=""
transform=""
case "$style" in
    R)  ;;
    B)  subname="Bold"
	transform="ExpandStroke(50, 0, 1, 0, 1)" ;;
    I)  subname="Italic"
	transform="Skew(13)" ;;
    BI) subname="BoldItalic"
	transform="ExpandStroke(50, 0, 1, 0, 1); Skew(13)" ;;
    *)  usage; exit 2 ;;
esac
temp=$(mktemp)
cat > $temp <<EOF
Open(\$1);
SelectAll();
ClearInstrs();
$transform;
Simplify();
CorrectDirection();
ScaleToEm($size);
RoundToInt();
SetFontNames(\$fontname + "-$subname")
RenameGlyphs("Adobe Glyph List");
Generate(\$fontname + "$type");
EOF
fontforge -script $temp "$font"
rm -f $temp
