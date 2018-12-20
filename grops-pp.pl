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
use feature 'say';
use open qw/:locale :std/;
use utf8;
use Encode;

# see the cflags defined /usr/local/share/groff/current/tmac/ja.tmac.
my $p = "、。，．：；？！）〕］｝」』】";
my $q = "\x{3041}-\x{3096}\x{30A0}-\x{30FF}\x{4E00}-\x{9FFF}";
my $t;

#say STDERR "# @ARGV";
my $preconv;
if (@ARGV && $ARGV[0] =~ /troff/) {
  $preconv = 1;
  open STDOUT, "|-", @ARGV or die "$0: $!; running @ARGV\n";
}

while (<STDIN>) {
  chomp;
  depreconv() if $preconv;
  $t = $_, next unless defined $t;
  $t .= $_, next if /^[$q]/ && $t =~ /^[^.]/ && $t =~ /[$q]$/;
  s/^([.]\s*)(na|hy\s+0)$/${1}if n .$2/;
  s/([$p])([^$p\s])/$1 $2/gx if /^[^.]/;
  ($t, $_) = ($_, $t);
  preconv() if $preconv;
  say;
}
if ($_ = $t) {
  preconv() if $preconv;
  say;
}

close STDOUT;
exit($? >> 8);


sub preconv {
  s/[^\x00-\xff]/"\\[u".uc(unpack("H*", encode("UCS-2BE", $&)))."]"/eg;
}

sub depreconv {
  s/\\\[u([0-9A-F]+)\]/decode("UCS-2BE", pack("H*", $1))/eg;
}
