#!/bin/sh

set -eu

PATH=/usr/local/bin:$PATH

usage="usage: $(basename $0) [-av] [-s size] [-t .ext] [-n subname] style fontfile"

subname=""
while getopts n:s:t: OPT
do
    case $OPT in
        s) size=$OPTARG ;;
        t) type=$OPTARG ;;
        n) subname=$OPTARG ;;
	*) echo $usage >&2; exit 2 ;;
    esac
done
size=${size-1024}
type=${type-.ttf}
shift $((OPTIND - 1))
style=${1:?"$usage"}
font=${2:?"$usage"}
transform=""
case "$style" in
    R)  ;;
    B)  subname="Bold"
	transform="ExpandStroke(50, 0, 1, 0, 1)" ;;
    I)  subname="Italic"
	transform="Skew(13)" ;;
    BI) subname="BoldItalic"
	transform="ExpandStroke(50, 0, 1, 0, 1); Skew(13)" ;;
    *)  echo $usage >&2; exit 2 ;;
esac
[ -n "$subname" ] && subname="-$subname"
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
SetFontNames(\$fontname + "$subname")
RenameGlyphs("Adobe Glyph List");
Generate(\$fontname + "$type");
EOF
fontforge -script $temp "$font"
rm -f $temp
