#!/usr/bin/env perl

use strict;
use warnings;
use File::Basename;
use File::Spec::Functions;
use Getopt::Long;
use XML::Parser::Lite;
#use Data::Dumper;
#$Data::Dumper::Indent = 1;
#$Data::Dumper::Terse = 1;

my $prog = basename $0, '.pl';
my $map = shift;
unless (@ARGV) {
  die "usage: $prog textmap cmap ...\n";
}

my $groff_bin_path = join ':', grep defined, $ENV{GROFF_BIN_PATH}, "/usr/local/bin", $ENV{PATH};
my $groff_font_path = join ':', grep defined, $ENV{GROFF_FONT_PATH}, "/usr/local/share/groff/current/font";

my ($sys_map) = grep -f, map catfile($_, "devps/generate", $map), split ':', $groff_font_path;

my %map;
my %nmap;

sub textmap {
  my @field = @_;
  $nmap{$field[0]} += 0;
  $map{$field[0], $nmap{$field[0]}} = $field[1];
  $nmap{$field[0]} += 1;
}

sub mapped {
  my ($name, $groff_char) = @_;
  if ($nmap{$name}) {
    for (map $map{$name, $_}, 0 .. $nmap{$name} - 1) {
      return 1 if defined && $_ eq $groff_char;
    }
  }
  return 0;
}

$map && open(MAP, $map) || open(MAP, $sys_map) ||
    die "$prog: can't open '$map' or '$sys_map': $!\n";
while (<MAP>) {
  next if /^#/;
  chop;
  my @field = split(' ');
  next if $#field < 0;
  if ($#field == 1) {
    if ($field[1] eq "space") {
      # The PostScript character "space" is automatically mapped
      # to the groff character "space"; this is for grops.
      warn "you are not allowed to map to " .
	"the groff character 'space'";
    }
    elsif ($field[0] eq "space") {
      warn "you are not allowed to map " .
	"the PostScript character 'space'";
    }
    else {
      textmap(@field);
    }
  }
}
close(MAP);

my $cmap_format;

XML::Parser::Lite->new(Handlers => {
  Start => sub {
    my ($self, $tag, %args) = @_;
    if ($tag =~ /^cmap_format_(\d+)$/) {
      $cmap_format = $1 + 0;
    }
    if ($tag eq "map" && $cmap_format && $cmap_format != 6) {
      my $name = $args{name};
      if ($args{code}) {
	my ($code) = map eval, @args{qw/code/};
	my $groff_char = sprintf "u%04X", $code;
	if ($name) {
	  textmap($name, $groff_char) unless mapped($name, $groff_char);
	}
      }
      if ($args{uv} && $args{uvs}) {
	my ($uv, $uvs) = map eval, @args{qw/uv uvs/};
	my $groff_char = sprintf "u%04X_%04X", $uv, $uvs;
	if ($name) {
	  textmap($name, $groff_char) unless mapped($name, $groff_char);
	} else {
	  # If there is no ps glyph name, try Unicode names with both
	  # 'uni' and 'u' prefixes. see $unicodepsname in afmtodit.
	  #my @name = (sprintf("u%04X", $uv), sprintf("uni%04X", $uv));
	  my @name = (sprintf $uv >= 0x10000? "u%04X" : "uni%04X", $uv);
	  for my $name (@name) {
	    #print "$cmap_format $name => $groff_char\n";
	    textmap($name, $groff_char) unless mapped($name, $groff_char);
	  }
	}
      }
    }
  },
  End => sub {
    my ($self, $tag, %args) = @_;
    if ($tag =~ /^cmap_format_\d+$/) {
      $cmap_format = 0;
    }
  },
})->parse(join '', <>);


my ($afmtodit) = grep -r, map catfile($_, 'afmtodit'), split ':', $groff_bin_path;

my %unicode_decomposed = ();
if (open my $f, "<", $afmtodit) {
  my $s = join '', <$f>;
  if ($s =~ /%unicode_decomposed\s*=\s*(\(.*?\))\s*;/s) {
    %unicode_decomposed = eval $1;
  }
}

delete @unicode_decomposed{map sprintf("%X", $_), 0xF900 .. 0xFAFF, 0x2F800 .. 0x2FA1F};
for my $name (grep $nmap{$_}, map +("uni$_", "u$_"), keys %unicode_decomposed) {
  delete $map{$name, $_} for 0 .. $nmap{$name} - 1;
  delete $nmap{$name};
}

for my $name (sort keys %nmap) {
  print "$name $map{$name, $_}\n" for 0 .. $nmap{$name} - 1;
}
