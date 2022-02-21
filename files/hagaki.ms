.ig
cat <<END >Makefile
GROFF?=		/usr/local/bin/groff -Tpdf -P-p${papersize} -P-l -dpaper=a6l \
                -rdebug=$(or ${debug}, ${DEBUG}, 0) -rnenga=$(or ${nenga}, ${NENGA}, 0) \
		-pk -mja -ms hagaki.ms
GS_BATCH?=	gs -dNOPAUSE -dQUIET -dBATCH
PDFWRITE?=	$(GS_BATCH) -sDEVICE=pdfwrite -dPrinted=false

%.pdf:	%.ms $(MAKEFILE_LIST)
	$(GROFF) -rnenga=$(or ${nenga}, ${NENGA}, 0) $< | $(PDFWRITE) -sOutputFile=$@ -

clean:
	rm -f *.pdf
END
..
.nr HM 0
.nr FM 0
.nr PO 0
.nr PI 0
.
.nr LL     +1.6i
.nr LL-To   \n[LL]u
.nr LL-From \n[LL]u
.nr LL-From -0.1i
.
.\" papersize: hagaki (borderless)
.nr ZI-To   1.2c    \" space from top (mk) to the To-postalcode
.nr ZS-To   0.8c    \" space from right edge (mk) to the To-postalcode
.
.nr AI-To   3c      \" space above the To-Address
.nr AS-To   1c      \" space to the right of the To-Address
.
.nr ZI-From 13.7c   \" Space from top to the From-postalcode
.nr ZS-From  6.55c  \" Space from right edge to the From-postalcode
.
.nr AI-From 8.5c    \" space above the From-Address
.nr AS-From 7.1c    \" space to the right of the To-Address
.
.if \n[nenga] \{\
.  nr AI-From -1.4c
.  nr ZI-From -1.4c
.  nr LL-To   -1.4c
.  nr LL-From -1.4c
.\}
.
.de MediaBox
.  nr PI 0
.  PP
.  rt 0
.  rs
.
.\" hagaki: 14.8x10.0cm
.  nr P3x 14.8c
.  nr P3y 10.0c
.
.  nr P1x 0
.  nr P1y 0
.  nr P2x \\n[P3x]u
.  nr P2y 0
.  nr P4x 0
.  nr P4y \\n[P3y]u
.
.\" sp -1
.  nr P1y -\\n[.v]u
.  nr P2y -\\n[.v]u
.  nr P3y -\\n[.v]u
.  nr P4y -\\n[.v]u
.
.\" move to inner
.  nr inner 0.02c
.  nr P1x +\\n[inner]u
.  nr P1y +\\n[inner]u
.  nr P2x -\\n[inner]u
.  nr P2y +\\n[inner]u
.  nr P3x -\\n[inner]u
.  nr P3y -\\n[inner]u
.  nr P4x +\\n[inner]u
.  nr P4y -\\n[inner]u
.
.  nop \Z'\h'\\n[P1x]u'\v'\\n[P1y]u'\D'l  0    +0.5i''\c
.  nop \Z'\h'\\n[P1x]u'\v'\\n[P1y]u'\D'l  0    -0.5i''\c
.  nop \Z'\h'\\n[P1x]u'\v'\\n[P1y]u'\D'l +0.5i  0''\c
.  nop \Z'\h'\\n[P1x]u'\v'\\n[P1y]u'\D'l -0.5i  0''\c
.  nop \Z'\h'\\n[P2x]u'\v'\\n[P2y]u'\D'l  0    +0.5i''\c
.  nop \Z'\h'\\n[P2x]u'\v'\\n[P2y]u'\D'l  0    -0.5i''\c
.  nop \Z'\h'\\n[P2x]u'\v'\\n[P2y]u'\D'l -0.5i  0''\c
.  nop \Z'\h'\\n[P2x]u'\v'\\n[P2y]u'\D'l +0.5i  0''\c
.  nop \Z'\h'\\n[P3x]u'\v'\\n[P3y]u'\D'l  0    -0.5i''\c
.  nop \Z'\h'\\n[P3x]u'\v'\\n[P3y]u'\D'l  0    +0.5i''\c
.  nop \Z'\h'\\n[P3x]u'\v'\\n[P3y]u'\D'l -0.5i  0''\c
.  nop \Z'\h'\\n[P3x]u'\v'\\n[P3y]u'\D'l +0.5i  0''\c
.  nop \Z'\h'\\n[P4x]u'\v'\\n[P4y]u'\D'l  0    -0.5i''\c
.  nop \Z'\h'\\n[P4x]u'\v'\\n[P4y]u'\D'l  0    +0.5i''\c
.  nop \Z'\h'\\n[P4x]u'\v'\\n[P4y]u'\D'l  0.5i  0''\c
.  nop \Z'\h'\\n[P4x]u'\v'\\n[P4y]u'\D'l -0.5i  0''\c
..
.
.ds FAM M
.
.ds LH
.ds CH
.ds RH
.
.PS
define putnum {
  w = $2
  h = $3
  b = 0.63
  if ($1 != "") then {
    move right h*b
    line invis up w $1 aligned
    move left h*b
  } else {
    move up w
  }
}
define boxnum {
  w = $2
  h = $3
  line up w
  line right h
  line down w
  line left h
  putnum($1, w, h)
}
.PE
.
.de setup-postalcode
.  nr POSTALCODE.i 0
.  nr POSTALCODE.j 0
.  while (\\n[POSTALCODE.i] < 7) \{\
.    ds POSTALCODE.\\n[POSTALCODE.i] \\$1
.    substring POSTALCODE.\\n[POSTALCODE.i] \\n[POSTALCODE.j] \\n[POSTALCODE.j]
.    ie '\\*[POSTALCODE.\\n[POSTALCODE.i]]'' \
.      break
.    el .ie '\\*[POSTALCODE.\\n[POSTALCODE.i]]'-' \
.      \" do nothing
.    el \
.      nr POSTALCODE.i +1
.    nr POSTALCODE.j +1
.  \}
..
.de psvs
.  ie \\n[.$]>=1 .ps \\$1
.  el .ps
.  ie \\n[.$]>=2 .vs (u;\\n[.ps] * \\$2)
.  el .vs (u;\\n[.ps] * 1600 / 1000)
..
.de To
.  if \\n[Line]>0 .bp
.  if \\n[debug] .MediaBox
.  nr Line 0
.  if dSignature .Signature
.  if \\n[.$] .Postalcode \\$1
.  Address
..
.de Address
.  rt 0
.  rs
.  sp \\n[AS-To]u
.  sp -1
.  nr PI \\n[AI-To]u
.  nr PI +2m
.  nr LL \\n[LL-To]u
.  PP
.  in \\n[PI]u
.  ti -2m
.  nr Line 1
.  ft \*[FAM]V
.  psvs +10
.  fi
.  ad l
.  itc 1 Address2
..
.de Address2
.  br\"p
.  nr Line +1
.  itc 1 Address2
.  fi
.  ad b
.  rj 1
..
.de Name
.  brp
.  if (\\n[Line] < 3) .sp
.  if (\\n[Line] < 4) .sp 0.5
.  nr Line +99
.  PP
.  ft \*[FAM]V
.  psvs +25 130/100
.  itc 1 Name
.  fi
.  ad b
..
.\" https://www.post.japanpost.jp/zipcode/zipmanual/p05.html
.de Postalcode
.  setup-postalcode \\$1
.  itc 0
.  PP
.  rt 0
.  rs
.  sp \\n[ZS-To]u
.  sp -1
.  sp -0.2c             \" xxxxx
.  ft OCRB
.  ps 13
.PS
   cm = 1 / 2.54
   w = 0.57*cm
   h = 0.80*cm
   d1 = 0.13*cm
   d2 = d1 + 0.06*cm
.PE
.  ie \\n[debug] \{\
.PS
.  in \\n[ZI-To]u
   boxnum("\\*[POSTALCODE.0]", w, h); move up d1
   boxnum("\\*[POSTALCODE.1]", w, h); move up d1
   boxnum("\\*[POSTALCODE.2]", w, h); move up d2
   boxnum("\\*[POSTALCODE.3]", w, h); move up d1
   boxnum("\\*[POSTALCODE.4]", w, h); move up d1
   boxnum("\\*[POSTALCODE.5]", w, h); move up d1
   boxnum("\\*[POSTALCODE.6]", w, h)
.  in
.PE
.  \}
.  el \{\
.PS
.  in \\n[ZI-To]u
   putnum("\\*[POSTALCODE.0]", w, h); move up d1
   putnum("\\*[POSTALCODE.1]", w, h); move up d1
   putnum("\\*[POSTALCODE.2]", w, h); move up d2
   putnum("\\*[POSTALCODE.3]", w, h); move up d1
   putnum("\\*[POSTALCODE.4]", w, h); move up d1
   putnum("\\*[POSTALCODE.5]", w, h); move up d1
   putnum("\\*[POSTALCODE.6]", w, h)
.  in
.PE
.  \}
.  ft
.  ps
.  if (\\n[Line]>0) .Address
..
.de From
.  setup-postalcode \\$1
.  itc 0
.  PP
.  rt 0
.  rs
.  sp \\n[ZS-From]u
.  sp -1
.  sp -0.2c             \" xxxxx
.  ft OCRB
.  ps 10
.PS
   cm = 1 / 2.54
   w = 0.40*cm
   h = 0.65*cm
   d1 = 0
   d2 = 0.1*cm
.PE
.  ie \\n[debug] \{\
.PS
.  in \\n[ZI-From]u
   boxnum("\\*[POSTALCODE.0]", w, h); move up d1
   boxnum("\\*[POSTALCODE.1]", w, h); move up d1
   boxnum("\\*[POSTALCODE.2]", w, h); move up d2
   boxnum("\\*[POSTALCODE.3]", w, h); move up d1
   boxnum("\\*[POSTALCODE.4]", w, h); move up d1
   boxnum("\\*[POSTALCODE.5]", w, h); move up d1
   boxnum("\\*[POSTALCODE.6]", w, h)
.  in
.PE
.  \}
.  el \{\
.PS
.  in \\n[ZI-From]u
   putnum("\\*[POSTALCODE.0]", w, h); move up d1
   putnum("\\*[POSTALCODE.1]", w, h); move up d1
   putnum("\\*[POSTALCODE.2]", w, h); move up d2
   putnum("\\*[POSTALCODE.3]", w, h); move up d1
   putnum("\\*[POSTALCODE.4]", w, h); move up d1
   putnum("\\*[POSTALCODE.5]", w, h); move up d1
   putnum("\\*[POSTALCODE.6]", w, h)
.  in
.PE
.  \}
.  ft
.  rt 0
.  rs
.  sp \\n[AS-From]u     \" right margin
.  sp -1
.  nr PI \\n[AI-From]u  \" top margin
.  nr LL \\n[LL-From]u
.  PP
.  in \\n[PI]u
.  ti -1m
.  ft \*[FAM]V
.  psvs 11
.  itc 1 From2
.  fi
.  ad l
..
.de From2
.  brp
.  PP
.  in \\n[PI]u
.  ft \\*[FAM]V
.  itc 1 From2
.  fi
.  ad b
..
.
.ds @rotate \
\\*[pp:nrsp ]\
\R'@rotate.w (\w'\\$1'/2)'\
\R'@rotate.h (\\n[rst]-(\\n[rsb]))'\
\X'ps: exec gsave currentpoint 2 copy translate -90 rotate neg exch neg exch translate'\
\Z'\v'\\n[@rotate.h]u'\h'0.35-\\n[@rotate.w]u'\\$1'\
\X'ps: exec grestore'\
\h'\\n[@rotate.h]u'\
\\*[pp:nrsp ]
.
.ig ..
.\" -*- nroff -*-
.\" (address.ms)
.\" pp-ja 34
.nr pp:nrsp-width \n[.ss]/2
.als b @rotate
.\"----------------------------------------
.de Signature
.  From 123-4567
◯◯市◯区◯◯◯\\*[b x]◯◯\\*[b xx]\-\\*[b xx]
.  rj 1
◯◯◯◯◯◯◯◯◯◯\\*[b xxx]◯
.  psvs +2
◯◯◯◯
..
.\"----------------------------------------
.To 123-4567
.if \n[nenga] .ps -3
○○市○区○○○○丁目○○\-○○
◯◯◯◯◯◯◯◯◯◯◯◯◯
.Name
◯◯ ◯◯◯ 様
...
