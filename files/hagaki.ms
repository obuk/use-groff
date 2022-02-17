.ig
cat <<END >Makefile
GROFF?=		/usr/local/bin/groff -Tpdf -P-pa6 -P-l -dpaper=a6l -pk -mja -ms	hagaki.ms
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
.
.nr ZI-To   0.35i   \" space from top (mk) to the To-postalcode
.nr ZS-To   0.09i   \" space from right edge (mk) to the To-postalcode
.
.nr ZI-From 5.55i   \" Space from top to the From-postalcode
.nr ZS-From 2.5i    \" Space from right edge to the From-postalcode
.
.nr AI-To   1i      \" space above the To-Address
.nr AS-To   0.2i    \" space to the right of the To-Address
.
.nr AI-From 2.7i    \" space above the From-Address
.nr AI-From 3.3i    \" space above the From-Address
.nr AS-From 2.75i   \" space to the right of the To-Address
.
.if \n[nenga] \{\
.  nr AI-From -0.65i
.  nr ZI-From -0.65i
.  nr LL      -0.65i
.\}
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
  box_visible = 1
  if (box_visible) then {
    line up w
    line right h
    line down w
    line left h
  } else {
    line invis up w
    line invis right h
    line invis down w
    line invis left h
  }
  if ($1 != "") then {
    move right h*b
    line invis up w $1 aligned
    move left h*b
  } else {
    move up w
  }
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
.  if (\\n[Line]>0) .bp
.  nr Line 0
.  if dSignature .Signature
.  if \\n[.$] .Postalcode \\$1
.  Address
..
.de Address
.  rt
.  sp \\n[AS-To]u
.  nr PI \\n[AI-To]u
.  nr PI +2m
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
.de Postalcode
.  setup-postalcode \\$1
.  itc 0
.  PP
.  rt
.PS
.  ft OCRB
.  ps 13
.  in \\n[ZI-To]u
.  sp \\n[ZS-To]u
   w = 0.65 / 2.54
   h = 0.90 / 2.54
   d1 = 0.035
   d2 = 0
   putnum("\\*[POSTALCODE.0]", w, h); move up d1
   putnum("\\*[POSTALCODE.1]", w, h); move up d1
   putnum("\\*[POSTALCODE.2]", w, h); move up d2
   putnum("\\*[POSTALCODE.3]", w, h); move up d1
   putnum("\\*[POSTALCODE.4]", w, h); move up d1
   putnum("\\*[POSTALCODE.5]", w, h); move up d1
   putnum("\\*[POSTALCODE.6]", w, h)
.  ft
.  ps
.  in
.PE
.  if (\\n[Line]>0) .Address
..
.de From
.  setup-postalcode \\$1
.  itc 0
.  PP
.  rt
.PS
.  ft OCRB
.  ps 10
.  in \\n[ZI-From]u
.  sp \\n[ZS-From]u
   w = 0.42 / 2.54
   h = 0.65 / 2.54
   d1 = 0
   d2 = 0.03
   putnum("\\*[POSTALCODE.0]", w, h); move up d1
   putnum("\\*[POSTALCODE.1]", w, h); move up d1
   putnum("\\*[POSTALCODE.2]", w, h); move up d2
   putnum("\\*[POSTALCODE.3]", w, h); move up d1
   putnum("\\*[POSTALCODE.4]", w, h); move up d1
   putnum("\\*[POSTALCODE.5]", w, h); move up d1
   putnum("\\*[POSTALCODE.6]", w, h)
.  ft
.PE
.  rt
.  sp \\n[AS-From]u     \" right margin
.  nr PI \\n[AI-From]u  \" top margin
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
