#!/usr/bin/env perl

use strict;
use warnings;
use File::Basename;
use File::Spec::Functions;
# cpanm https://github.com/obuk/font-ttf.git
use Font::TTF::Font;

my $prog = basename $0, '.pl';
my $map = shift;
die "usage: $prog textmap ttf ...\n" unless my $ttf = shift;

my $groff_bin_path = join ':', grep defined, $ENV{GROFF_BIN_PATH}, "/usr/local/bin", $ENV{PATH};
my $groff_font_path = join ':', grep defined, $ENV{GROFF_FONT_PATH}, "/usr/local/share/groff/current/font";

my ($sys_map) = grep -f, map catfile($_, "devps/generate", $map), split ':', $groff_font_path;
$map && open(MAP, $map) || open(MAP, $sys_map) ||
    die "$prog: can't open '$map' or '$sys_map': $!\n";
print for <MAP>;
close(MAP);

my ($afmtodit) = grep -r, map catfile($_, 'afmtodit'), split ':', $groff_bin_path;

my %unicode_decomposed = ();
if (open my $f, "<", $afmtodit) {
  my $s = join '', <$f>;
  if ($s =~ /%unicode_decomposed\s*=\s*(\(.*?\))\s*;/s) {
    %unicode_decomposed = eval $1;
  }
}

delete @unicode_decomposed{map sprintf("%X", $_), 0xF900 .. 0xFAFF, 0x2F800 .. 0x2FA1F};

my $f = Font::TTF::Font->open($ttf) || die "$prog: can't open '$ttf': $!\n";
$f->{cmap}->read;
$f->{post}->read;

print "# $ttf cmap\n";
for (grep !$unicode_decomposed{sprintf "%04X", $_}, keys %{$f->{cmap}->find_ms->{val}}) {
    next unless my $gid = $f->{cmap}->ms_lookup($_);
    print $f->{post}{VAL}[$gid], ' ', sprintf("u%04X", $_), "\n";
}
for (keys %{$f->{cmap}->find_uvs->{val}}) {
    next unless my $gid = $f->{cmap}->uvs_lookup($_);
    print $f->{post}{VAL}[$gid], ' ', sprintf("u%04X_%04X", split $;), "\n";
}
