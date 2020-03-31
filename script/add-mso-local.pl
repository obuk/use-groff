#!/usr/bin/env perl

use strict;
use warnings;
use File::Basename;
use Getopt::Long;

sub usage {
  die "usage: ", basename($0), " [-n name] [-l localname] file\n";
}

GetOptions("name=s" => \ my $name, "local=s" => \ my $local) and @ARGV
  or usage();

$name  //= basename $ARGV[0] if @ARGV;
$local //= basename($name, '.tmac') . '.local' if $name;

my @main;
my @tail;
my $tail;
while (<>) {
  unless ($tail) {
    $tail = 1
      if /^[.]\\" (Editor|Emacs) [Ss]ettings/
      || /^[.]\\" Local Variables:/ && @main >= 3
      || /^[.]\\".*?(no|not|n\'t let) blank lines creep in/
      || /^[.]\\".*?\bmake sure this is the last line/
      || $name && /^[.]\\" end of \Q$name\E/
      || $name && /^[.]\\" \Q$name\E: end of file/
      || /^[.]\\\" EOF$/;
  }
  if ($tail) {
    push @tail, $_;
  } else {
    push @main, $_;
  }
}
unshift @tail, pop @main while @main && @tail && $main[-1] =~ /^[.]\\\"/;
print for @main;

if ($local) {
  unshift @tail, <<END unless @tail;
.\\\" EOF
END
  unshift @tail, ".\n" unless $tail[-1] =~ /^\.$/;
  unshift @tail, <<END;
.\\\" Load local modifications.
.do mso $local
END
  unshift @tail, ".\n" unless @main && $main[-1] =~ /^\.$/;
}
print for @tail;
