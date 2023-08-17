#!/usr/bin/env perl

use strict;
use warnings;
use feature 'say';
use Clone 'clone';
use Getopt::Long;
use File::Spec::Functions;
use File::Basename;

use Data::Dumper;
$Data::Dumper::Indent = 1;
$Data::Dumper::Terse = 1;

my $progname = basename $0, '.pl';

my @glyph;
my $allglyphs;
my %opt;
my $verbose;

GetOptions(
  "glyphs=s" => \ @glyph,
  "allglyphs" => \ $allglyphs,
  "palt" => \ $opt{palt},
  "vpal" => \ $opt{vpal},
  "verbose" => \ $verbose,
)
or die("Error in command line arguments\n");

$opt{$progname} = 1 unless grep $_, values %opt;

my %glyph = map +($_ => 1), @glyph;

my @kw = (qw/ StartChar Encoding AltUni2 Width VWidth GlyphClass Flags
              AnchorPoint LayerCount Fore SplineSet Kerns2 VKerns2
              Substitution2 AlternateSubs2 Position2 Ligature2 /);

my %char;

&main;

sub main {
  my %kw_seen = map +($_ => 1), @kw;
  my $c;
  my $s;
  my $in_chars;
  while (<>) {
    chop;
    if (/^BeginChars:/) {
      $in_chars = 1;
      say;
    } elsif (/EndChars/) {
      $in_chars = 0;
      position2($opt{palt} ? qr/'palt'/ : $opt{vpal} ? qr/'vpal'/ : undef);
      print_chars();
      say;
    } elsif (!$in_chars) {
      say;
    } elsif (/^(StartChar):\s+(.*)/) {
      $c = {};
      $c->{$1} = $2;
      $c->{-selected} = 1 if $allglyphs || $glyph{$2};
    } elsif (/^EndChar/) {
      $char{$c->{StartChar}} = $c;
      $c = undef;
    } elsif (/^SplineSet/) {
      $s = [];
    } elsif (/^EndSplineSet/) {
      $c->{SplineSet} = $s;
      $s = undef;
    } elsif ($s) {
      push @$s, $_;
    } elsif (/^([^:]+)(?:[:]\s*(.*))?/) {
      my ($k, $v) = ($1, $2);
      push @kw, $k if !$kw_seen{$k}++;
      if ($c) {
        if ($k) {
          if ($k eq 'Encoding') {
            my @enc = split /\s+/, $v;
            $c->{$k} = \@enc;
	    $c->{-selected} = 1 if $glyph{sprintf "u%04X", $enc[0]};
          } elsif (exists $c->{$k}) {
            $c->{$k} = [ ref $c->{$k} ? (@{$c->{$k}}, $v) : ($c->{$k}, $v) ];
          } else {
            $c->{$k} = $v;
          }
        } else {
          die "#1 $_";
        }
      } else {
        die "#2 $_";
      }
    } elsif (/./) {
      die "#3 $_";
    } else {
      #say;
    }
  }
}


sub position2 {
  my ($grep) = @_;
  return undef unless $grep;
  for my $cid (sort keys %char) {
    my $c = $char{$cid};
    next unless $c->{-selected};
    if ($c->{Position2}) {
      my @p2 = map { ref ? @$_ : $_ } $c->{Position2};
      if (my ($palt) = grep /$grep/, @p2) {
        $c->{Position2} = [ grep $_ ne $palt, @p2 ];
        delete $c->{Position2} if @{$c->{Position2}} == 0;
        my %p = map +($_ => ($palt =~ /$_=(\S+)/)[0]), qw/dx dy dh dv/;
        $c->{Width} += $p{dh} + $p{dv};
        my @ss;
        for (@{$c->{SplineSet}}) {
          s/^\s+//;
          my @s = split /\s+/;
          if ($s[2] eq 'm' || $s[2] eq 'l') {
            $s[0] += $p{dx};
            $s[1] += $p{dy};
          } elsif ($s[6] eq 'c') {
            $s[0] += $p{dx};
            $s[1] += $p{dy};
            $s[2] += $p{dx};
            $s[3] += $p{dy};
            $s[4] += $p{dx};
            $s[5] += $p{dy};
          } else {
            die "can't parse SplineSet '@s' in ", $c->{StartChar}, "\n";
          }
          push @ss, "@s";
        }
        $c->{SplineSet} = \@ss;
      }
    }
  }
}


sub substitution2 {
  my ($grep) = @_;
  for my $cid (sort keys %char) {
    my $c = $char{$cid};
    next unless $c->{-selected};
    if ($c->{Substitution2}) {
      my @s2 = map { ref ? @$_ : $_ } $c->{Substitution2};
      my @tmp = @s2;
      for my $match (grep /$grep/, @s2) {
        @tmp = grep $_ ne $match, @tmp;
        if (my ($xid) = $match =~ /".*?" (\S+)/) {
          if (my $x = $char{$xid}) {
            for (qw/Width SplineSet Kerns2 VKerns2 Substitution2
                    AlternateSubs2 Position2 Ligature2/) {
              delete $c->{$_};
              $c->{$_} = clone($x->{$_}) if $x->{$_};
            }
          }
        }
      }
      if (@tmp != @s2) {
        $c->{Substitution2} = \@tmp;
        delete $c->{Substitution2} if @{$c->{Substitution2}} == 0;
      }
    }
  }
}


sub print_chars {
  my $nl;
  for my $cid (sort { $char{$a}->{Encoding}->[2] <=> $char{$b}->{Encoding}->[2] } keys %char) {
    my $c = $char{$cid};
    #next if $c->{-merged};
    say "" if $nl;
    $nl = 0;
    if (my @pp = map pp($c, $_), 'StartChar', @kw) {
      say for @pp;
      say 'EndChar';
      $nl = 1;
    }
  }
}


sub pp {
  my ($c, $k) = @_;
  if (exists $c->{$k}) {
    my $v = $c->{$k};
    delete $c->{$k};
    if (defined $v) {
      if (ref $v) {
        if ($k eq 'SplineSet') {
          return ($k, @$v, "End".$k);
        } elsif ($k eq 'Encoding') {
          return "$k: @$v" if $v;
        } else {
          return map "$k: $_", @$v;
        }
      } else {
        return "$k: $v";
      }
    } else {
      return "$k";
    }
  } else {
    return ();
  }
}
