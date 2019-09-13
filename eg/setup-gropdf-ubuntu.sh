#!/bin/sh

# setup gropdf ja ubuntu

set -eu

GROPDF_CURRENT=http://git.savannah.gnu.org/cgit/groff.git/plain/src/devices/gropdf/gropdf.pl

cd ${WORK-work}

# config, patch, install gropdf
CONFIG_PL=$(mktemp)
trap "rm -f $CONFIG_PL; exit 1" 1 2 3 15

cat > $CONFIG_PL <<'END'
use strict;
my %c = (PERL => $^X);
/^\$cfg\{(\w+)\}\s*=\s*'([^']*)'/ and $c{$1} = $2 while <ARGV>;
$c{VERSION} = $c{GROFF_VERSION};
$c{GROFF_FONT_DIR} = $c{GROFF_FONT_PATH};
s|[@](\w+)[@]|$c{$1}//$&|eg, print while <>;
END

PATH_GROPDF=`which gropdf`
GROPDF=${GROPDF:-"$(basename $PATH_GROPDF)-$(date +%m%d)"}
curl -L $GROPDF_CURRENT | perl -w $CONFIG_PL $PATH_GROPDF >gropdf
rm -f $CONFIG_PL
patch <gropdf.patch

sudo install -m755 gropdf $(dirname $PATH_GROPDF)/$GROPDF

(grep -v ^postpro /usr/share/groff/current/font/devpdf/DESC
 echo postpro $GROPDF) >DESC
sudo install -m644 DESC /usr/share/groff/current/font/devpdf/

# ubuntu
# zcat `man -L ja -w 7 groff` | groff -Tpdf -mja -man -Dutf8
# | gs -sDEVICE=pdfwrite -dPrinted=false -dNOPAUSE -dQUIET -dBATCH -sOutputFile=a.pdf -
