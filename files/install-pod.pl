#!/usr/bin/env perl

use common::sense;
use Config;
use Cwd;
use File::Basename;
use File::Spec::Functions;
use Getopt::Long;
use Perl6::Slurp;
use Pod::POM;

GetOptions(
  "d|dest=s" => \ my $dest,
  "L|lang=s" => \ my $lang,
  "v|verbose" => \ my $verbose,
  "t|twist=s%" => \ my %twist,
  "default-version=s" => \ my $default_version,
  "no-perldelta-fixes" => \ my $no_perldelta_fixes,
) or die "usage: $0 [-d dest-dir | -L lang ] [-v] pod-files\n";

$dest ||= join "/", $Config{installsitelib}, 'POD2', uc $lang if $lang;
$dest ||= $Config{installsitelib};
$default_version ||= '0.0.1';

sub get_name {
  my %options;
  my $parser = Pod::POM->new(\%options);

  # parse from a text string
  my $pom = $parser->parse_text($_[0])
    || die $parser->error();

  my @name;

  my ($head1) = $pom->head1;
  my @block = ('');
  for (split /\n/, $head1->content()) {
    if (/^=begin\s+(\w+)/ .. /^=end $block[-1]/) {
      push @block, $1 if /^=begin/;
      pop @block if /^=end/;
    } elsif (@name = /^    \s* (?:[BCFI]<)? ((?&NAME)) (?:>)? \s*
                      (?:, \s* (?:[BCFI]<)? ((?&NAME)) (?:>)? \s* )* --?
                      (?(DEFINE) (?<NAME> (?:\w+(?:(?:-|::)\w+)*(?:\.\w+)*) ))/x) {
      @name = grep defined && /./, map { s/^\s+//; s/\s$//; $_ } @name;
      last;
    }
  }

  @name;
}

sub get_version {
  my @path = split "/", $_[0];
  shift @path if $path[0] eq '.';
  $path[0] =~ s/^(v?\d+[\d\_\.]+)(-RC\d)?$// or
    $path[0] =~ s/-(v?\d+[\d\_\.]+)(-|$)/$2/ or
    $path[-1] =~ s/-(v?\d+[\d\_\.]+)(\.pod)/$2/;
  my $version = $1;
  $version =~ tr [_] [.] if $version =~ /[_]/ && $version !~ /[.]/;
  $version;
}

my %pods;

local $/ = undef;
while (<ARGV>) {
  next unless -f $ARGV;
  (my $file = $ARGV) =~ s/^\.\///;

  my $version = get_version($file);
  unless ($version) {
    $version = $default_version;
    if ($version) {
      warn "$ARGV: can't get version; use default $version\n" if $verbose;
    } else {
      warn "$ARGV: can't get version\n";
      next;
    }
  }
  unless (my $v = eval { version->parse($version); }) {
    warn "$ARGV: can't parse version $version\n";
    next;
  }

  my @name = grep defined && /./, split /\s*,\s*/, $twist{$file};
  @name = get_name($_) unless @name;
  unless (@name) {
    warn "$ARGV: can't get name\n";
    next;
  }

  if (!$no_perldelta_fixes) {
    if (grep /^perldelta$/, @name) {
      my @v = version->parse($version)->normal =~ /(\d+)/g;
      my $v = join '', @v;
      warn "$ARGV: name @name, version @v\n" if $verbose;
      $file = "/tmp/perl${v}delta.pod";
      if (open my $fd, ">", $file) {
        s/^perldelta/perl${v}delta/gm;
        print $fd $_;
        close $fd;
        @name = get_name($_);
        warn "$ARGV: rename to @name\n" if $verbose;
      } else {
        warn "$ARGV: can't rename to perl${v}delta\n";
        $file = $ARGV;
      }
    }
  }

  warn "$ARGV: name = @name, version = $version\n" if $verbose;
  $pods{$_}{$version} = $file for @name;
}

if (!$no_perldelta_fixes) {
  my @v = version->parse($Config{api_versionstring})->normal =~ /(\d+)/g;
  my $v = join '', @v;
  if (my $file = $pods{"perl${v}delta"}{$Config{api_versionstring}}) {
    local $_ = slurp $file;
    my $temp = "/tmp/perldelta.pod";
    if (open my $fd, ">", $temp) {
      s/^perl${v}delta/perldelta/gm;
      print $fd $_;
      close $fd;
      $pods{"perldelta"}{$Config{api_versionstring}} = $temp;
    }
  }
}

sub quote {
  my @q = map {
    (my $q = $_) =~ s/\s/\\$&/g;
    $q;
  } @_;
}

exit 0 unless %pods;

$ENV{CWD} ||= getcwd;
$ENV{DEST} ||= $dest;
$ENV{INSTALL} ||= 'install -C -D -m 0644';
$ENV{MKDIR} ||= 'mkdir -p';
for (qw/CWD DEST INSTALL MKDIR/) {
  my $v = $ENV{$_};
  say join " ", quote "$_=$v";
}

my %dir;
for (sort keys %pods) {
  next unless my @v = keys %{$pods{$_}};
  my ($v) = sort { version->parse($b) <=> version->parse($a) } @v;
  my $s = ${$pods{$_}}{$v};
  $s = join "/", '${CWD}', $s unless $s =~ /^\//;
  my $d = join "/", '${DEST}', split /::/;
  $d .= $1 if $s =~ /(\.\w+)$/;
  my $dir = dirname $d;
  say join ' ', quote '${MKDIR}', $dir unless $dir{$dir}++;
  say join ' ', quote '${INSTALL}', $s, $d;
}
