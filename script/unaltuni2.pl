#!/usr/bin/env perl

use strict;
use warnings;
use feature 'say';
use Getopt::Long;
use File::Spec::Functions;

GetOptions("glyphs=s"   => \ my @glyph,
           "allglyphs"  => \ my $allglyphs,
           "verbose"    => \ my $verbose)
or die("Error in command line arguments\n");

my %cfg = (RT_SEP => ':');
my %AGL_to_unicode;
Load_afmtodit();

if ($allglyphs) {
  @glyph = sort keys %AGL_to_unicode;

} else {

  # Checks @glyph with AGL_to_unicode, if the code in @glyph is
  # specified instead of the name, changes it to the name with
  # AGL_to_unicode.

  @glyph = do {
    my @tmp = %AGL_to_unicode;
    my @AGL_to_unicode;
    while (my ($k, $v) = splice @tmp, 0, 2) {
      push @AGL_to_unicode, [ $k, $v ];
    }
    my @list;
    my %seen;
    for my $k (@glyph) {
      my ($v) = $k =~ /^(?:u|uni)?([0-9A-F]+)$/;
      my @found = map $_->[0], grep $k eq $_->[0] || $v && $v eq $_->[1], @AGL_to_unicode;
      say STDERR "$0: $k ignored" unless @found;
      push @list, grep !$seen{$_}++, @found;
    }
    sort @list;
  };
}

my @char;
my %seen;
my $maxenc = 0;
my $c;
while (<>) {
  chop;
  if (/^(StartChar):\s+(.*)/) {
    $c = {};
    $c->{$1} = $2;
  } elsif ($c) {
    if (/^(StartChar|Encoding|AltUni2):\s+(.*)/) {
      $c->{$1} = $2;
    } elsif (/^EndChar\b/) {
      my @alt;
      if (my $alt = $c->{AltUni2}) {
        for (split /\s+/, $alt) {
          if (/^([\d\a-f]+)\.f{8}\.0$/) {
            (my $hex = $1) =~ s/^0+//;
            my ($name) = grep $AGL_to_unicode{$_} =~ /^0*$hex$/i, @glyph;
            if ($name) {
              my @enc = split /\s+/, $c->{Encoding};
              if ($verbose) {
                say STDERR "$0: creating $name (0x$hex) from $c->{StartChar}",
                  @enc? sprintf(" (0x%x)", $enc[0]) : ();
              }
              my $code = hex $hex;
              push @char, join "\n",
                "StartChar: $name",
                "Encoding: $code $code unknown",
                @{$c->{body}},
                "EndChar";
            } else {
              push @alt, $_;
            }
          } else {
            push @alt, $_;
          }
        }
      }
      say "StartChar: $c->{StartChar}";
      say "Encoding: $c->{Encoding}";
      say "AltUni2: @alt" if @alt;
      say for @{$c->{body} //= []};
      say "EndChar";
      my @enc = split /\s+/, $c->{Encoding};
      $maxenc = max($maxenc, $enc[2]);
      $c = undef;
    } else {
      push @{$c->{body} //= []}, $_;
    }
  } else {
    if (/^EndChars\b/) {
      for (@char) {
        s/^Encoding: (\S+) (\S+) (\S+)/do {
          $maxenc++;
          "Encoding: $1 $2 $maxenc";
        }/em;
        if (my ($name) = /StartChar: (\S+)/) {
          if ($seen{$name}++) {
            say STDERR "$0: glyph $name duplicated"
              if $verbose;
          }
        }
        say "";
        say;
      }
    }
    say;
  }
}


sub Load_afmtodit
{
    my @afmtodit = grep -x, map catfile($_, 'afmtodit'), grep /./ && -d,
        map split($cfg{RT_SEP}, $_), grep defined, $ENV{GROFF_BIN_DIR}, $ENV{PATH};
    if (@afmtodit) {
	open my $f, "<", $afmtodit[0];
	my $afmtodit = join '', <$f>;
	if ($afmtodit =~ /%AGL_to_unicode\s*=\s*(\(.*?\))\s*;/s) {
	    %AGL_to_unicode = eval $1;
	}
    }
    #Msg(0, "Could not find afmtodit") if !%AGL_to_unicode;
}

sub max {
  my $max = shift;
  $max = $_ > $max ? $_ : $max for grep defined, @_;
  $max;
}
