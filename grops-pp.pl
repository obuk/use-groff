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

our $VERSION = "0.02";

use feature 'say';
use open qw/:locale :std/;
use utf8;
use Encode;

use Getopt::Long qw(:config no_ignore_case require_order);
use File::Basename;
my $usage = join ' ', "usage:", basename($0),
  "[--help] [--version|-v] [--preconv|-p] [command|file...]";
GetOptions(
  "help" => \ my $help,
  "version|v" => \ my $version,
  "preconv|p" => \ my $preconv,
) or die "$usage\n";

if ($help) {
  say $usage;
  exit 0;
}

if ($version) {
  say join ' ', basename($0), "version", $VERSION;
  if (@ARGV) {
    exec @ARGV;
    die basename($0), ": can't exec: @ARGV\n";
  }
  exit 0;
}

# see the cflags defined /usr/local/share/groff/current/tmac/ja.tmac.
my $p = "、。，．：；？！）〕］｝」』】";
my $q = "\x{3041}-\x{3096}\x{30A0}-\x{30FF}\x{4E00}-\x{9FFF}";
my $t;

if (@ARGV && $ARGV[0] =~ /troff/) {
  if (open STDOUT, "|-", @ARGV) {
    @ARGV = ();
    $preconv = 1;
  }
}

while (<>) {
  chomp;
  depreconv() if $preconv;
  $t = $_, next unless defined $t;
  $t .= $_, next if /^[$q]/ && $t =~ /^[^.]/ && $t =~ /[$q]$/;
  ($t, $_) = ($_, $t);
  s/^([.]\s*)(na|hy\s+0)$/${1}if n .$2/;
  unless (/^([.]|\\&)/) {
    s/([$p])([^$p\s])/$1 $2/g;
    #s{[$q]+}{join "\\:", split //, $&}eg;
  }
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
  s/[^[:ascii:]]/"\\[u".uc(unpack("H*", encode("UCS-2BE", $&)))."]"/eg;
}

sub depreconv {
  s/\\\[u([0-9A-F]+)\]/decode("UCS-2BE", pack("H*", $1))/eg;
}
