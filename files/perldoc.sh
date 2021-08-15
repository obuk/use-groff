#!/bin/sh

set -eu

usage() {
    echo "usage: $(basename $0) [-L<lang>] [--ps|--pdf] ..." >&2
}

search_path() {
    local delim=';'
    (
        locate man.local an.tmac | xargs dirname | grep -v ^/iocage | uniq
    ) | grep . | tr '\n' "$delim" | sed "s/$delim\$//"
}

do_perldoc() {
    VERBOSE="${VERBOSE:-}"
    PERLDOC="${PERLDOC:-} -o nroff4"
    GROFF="${GROFF:-groff -mandoc}"
    TYPESETTER="${TYPESETTER:-}"
    GS="${GS:-gs}"
    #GS_BATCH="${GS_BATCH:-$GS -dNOPAUSE -dBATCH -dQUIET}"
    GS_BATCH="${GS_BATCH:-$GS -dNOPAUSE -dBATCH}"
    GS_PDFWRITE="${GS_PDFWRITE:-$GS_BATCH -sDEVICE=pdfwrite}"
    # if gs could not find t42 fonts, specify that path 
    FONTPATH="${FONTPATH:-/usr/local/share/groff/site-font/devps:/usr/share/groff/site-font/devps}"
    GS_PDFWRITE="$GS_PDFWRITE -sFONTPATH=$FONTPATH"

    while getopts "hVriDtumUFXlTn:d:o:M:w:L:f:q:v:a:-:" opt; do
        case "$opt" in
            -)
                case "${OPTARG}" in
                    ps|pdf)
                        TYPESETTER=$OPTARG
                        ;;
                    -)
                        break
                        ;;
                    *)
                        usage
                        exit 1
                        ;;
                esac
                ;;
            D)
                VERBOSE=true
                ;;
            L)
                lang=$OPTARG
                [ "$lang" = "ja" ] && PERLDOC_BIN=$(which perldocjp | xargs basename)
                [ -z "$PERLDOC_BIN" ] && PERLDOC="$PERLDOC -L $lang"
                PERLDOC="$PERLDOC -w __lang=$lang -w __search_path='$(search_path)'"
                #GROFF="$GROFF -m$lang"
                ;;
            *)
                PERLDOC="$PERLDOC -$opt"
                [ -z "${OPTARG:-}" ] || PERLDOC="$PERLDOC '$OPTARG'"
                ;;
        esac
    done

    shift $(($OPTIND - 1))
    
    GROFF="$GROFF -Dutf8 -dlocale=${lang:-C}.UTF-8"
    #GROFF="$GROFF -k"
    PIPELINE="${PERLDOC_BIN:-perldoc} $PERLDOC $*"
    case "$TYPESETTER" in
        ps)
	    PIPELINE="$PIPELINE | $GROFF -T$TYPESETTER"
            ;;
        pdf)
            if [ -z "$VERBOSE" ]; then
	        PIPELINE="$PIPELINE | $GROFF -T$TYPESETTER"
                PIPELINE="$PIPELINE | $GS_PDFWRITE -sOutputFile=- -"
            else
	        PIPELINE="$PIPELINE | $GROFF -T$TYPESETTER -P-d"
            fi
            ;;
    esac
    [ -z "$VERBOSE" ] || echo "# $PIPELINE" >&2
    eval "$PIPELINE"
}

do_perldoc "$@"
