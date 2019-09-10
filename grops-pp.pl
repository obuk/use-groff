#!/usr/bin/env perl

=encoding utf-8

=head1 NAME

grops-pp.pl - as a prepro of the grops.

=head1 SYNOPSYS

install this program grops-pp.pl as follows:

 install grops-pp.pl /usr/local/bin

and add prepro line to your devps/DESC.

 echo prepro grops-pp.pl >> DESC

=cut

use strict;
use warnings;

our $VERSION = "0.05";

use feature 'say';
use open qw/:locale :std/;
use utf8;
use Encode;
use File::Basename;

my $usage = join ' ', "usage:", basename($0), "prepro-opts troff troff-opts";
my @prepro = parse_option(qr/^-([bcFIpPw])(.*)/, qr/^-([glmv]+)$/);
my $version = grep defined && $_ eq -v, @prepro;
my @troff = @ARGV && shift @ARGV;
push @troff, parse_option(qr/^-([dfFImMnorTwW])(.*)/, qr/^-([abcivzCERU]+)/);

if ($version) {
  say join ' ', basename($0), "version", $VERSION;
}

my $preconv = 0;
if (@troff && $troff[0] =~ /troff/) {
  $preconv = 1;
  local $ENV{PATH} = join ':', grep defined, $ENV{GROFF_BIN_PATH}, $ENV{PATH};
  open STDOUT, "|-", @troff or die $usage;
}

# see the cflags defined /usr/local/share/groff/current/tmac/ja.tmac.
my $p = "、。，．：；？！）〕］｝」』】";
my $q = "\x{3041}-\x{3096}\x{30A0}-\x{30FF}\x{4E00}-\x{9FFF}";
my $t;

sub preproc {
while (<>) {
  chomp;
  unconv() if $preconv;
  $t = $_, next unless defined $t;
  $t .= $_, next if /^[$q]/ && $t =~ /^[^.]/ && $t =~ /[$q]$/;
  ($t, $_) = ($_, $t);
  s/^([.]\s*)(na|hy\s+0)$/${1}if n .$2/;
  unless (/^([.]|\\&)/) {
    s/([$p])([^$p\s])/$1 $2/g;
  }
  conv() if $preconv;
  say;
}
if ($_ = $t) {
  conv() if $preconv;
  say;
}
}

preproc() if !$version;
close STDOUT;
exit($? >> 8);


sub conv {
  s/[^[:ascii:]]/sprintf "\\[u%04X]", unpack "U", $&/eg;
}

sub unconv {
  s/\\\[u([0-9A-F]+)\]/pack "U*", hex $1/eg;
}

sub parse_option {
  my ($r1, $r2) = @_;
  my $sep = '';
  my @option;
  while (@ARGV) {
    $_ = shift @ARGV;
    unshift(@ARGV, $_), last if /^[-]$/ || /^[^-]/;
    if (/$r1/) {
      push @option, "-$1".$sep.(defined $2 && $2 ne '' ? $2 : shift @ARGV);
    } elsif (/$r2/) {
      push @option, map "-$_", split //, $1;
    } else {
      die "can't parse $_\n", "$usage\n";
    }
  }
  @option;
}
