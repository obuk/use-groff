#!/usr/bin/env perl

=encoding utf-8

=head1 NAME

pre-grops.pl - as a prepro of the grops.

=head1 SYNOPSYS

install this program pre-grops.pl as follows:

 install pre-grops.pl /usr/local/bin

and add prepro line to your devps/DESC.

 echo prepro pre-grops.pl >> DESC

=cut

use strict;
use warnings;

our $VERSION = "0.06";

use feature qw/say/;
use open qw/:locale :std/;
use utf8;
use Encode;
use File::Basename;
use File::Spec::Functions qw/rootdir catdir catfile/;
use YAML::Syck qw/Load Dump/;

sub run {
  my $self = bless {}, shift;

  eval { require Unicode::Normalize };

  my @prepro = parse_option(map qr/$_/, $self->rc("parse_option"));
  my @troff = shift @ARGV if @ARGV;
  push @troff, parse_option(map qr/$_/, $self->rc("troff.parse_option"));

  # show subprograms version
  say join ' ', basename($0), "version", $VERSION
    if grep defined && $_ eq -v, @prepro;

  $self->{use_conv} = 0;
  if (@troff && $troff[0] =~ /troff/) {
    $self->{use_conv} = 1;
    local $ENV{PATH} = join ':', grep defined, $ENV{GROFF_BIN_PATH}, $ENV{PATH};
    open STDOUT, "|-", @troff or die usage();
  }

  my $tee = $self->rc('tee');
  open STDOUT, "|-", "tee", $tee or die "can't open $tee: $!" if $tee;
  $self->prepro() if !grep /-v/, @prepro;
  close STDOUT;
  exit($? >> 8);
}


sub usage {
  my @usage = (@_, "\n") if @_;
  push @usage, "usage: ", basename($0), " grops-opts troff troff-opts", "\n";
  @usage;
}


sub parse_option {
  my $sep = '';
  my @option;
  while (@ARGV) {
    $_ = shift @ARGV;
    unshift(@ARGV, $_), last if /^[-]$/ || /^[^-]/;
    if (/$_[0]/) {
      push @option, "-$1".$sep.(defined $2 && $2 ne '' ? $2 : shift @ARGV);
    } elsif (/$_[1]/) {
      push @option, map "-$_", split //, $1;
    } else {
      die usage("unknown option: $_");
    }
  }
  @option;
}

sub prepro {
  my ($self) = @_;

  my %sp = (hwsp => ' ', hwnbsp => '\~');
  my %vsp = ();

  for my $sp (qw/sp nbsp/) {
    for my $xw (qw/hw zw qw/) {
      for ($xw.$sp) {
        $sp{$_} = $self->rc($_);
        $vsp{$_} = $self->rc("v".$_);
      }
    }
  }

  for my $sp (qw/sp nbsp/) {
    for my $xw (qw/hw zw qw/) {
      for (grep defined $sp{$_}, $xw.$sp) {
        $self->{sp}{$self->{$_} = $self->pua} = $sp{$_};
        #$self->puts(sprintf ".ds $_ \\[u%X]", ord($self->{$_}));
      }
    }
  }
  for my $xw (qw/hw zw qw/) {
    $self->{nbsp}{$self->{$xw."sp"}} = $self->{$xw."nbsp"};
  }

  for my $sp (qw/sp nbsp/) {
    for my $xw (qw/hw zw qw/) {
      for (grep defined $vsp{$_}, $xw.$sp) {
        $self->{vsp}{$self->{$_}} = $self->{$_}.$vsp{$_};
      }
    }
  }

  my $prologue = $self->rc('prologue');
  $self->puts($prologue) if $prologue;
  $self->puts(".lf ".$self->nr);

  my $mode_request = $self->rc('mode_request');
  my @mode = ($self->rc('mode_default') // 3);
  if (defined $ENV{PREPRODEBUG}) {
    $mode[0] = $ENV{PREPRODEBUG} + 0;
  }
  my $stop_tweaking;
  while (1) {
    last unless defined $self->getline($mode[-1]);
    if  (/$mode_request/m) {
      if (defined $1) {
        push @mode, $1;
      } elsif (@mode > 1) {
        pop @mode;
      }
    } elsif (/^\.\\\"/) {
      ;
    } elsif (/^\.\s*(de|am|ig)/ .. /^\.\./) {
      ;
    } elsif (/^\.\s*fc(?:\s+(.)(.)?)?$/) {
      $stop_tweaking = grep defined, $1, $2; # between TS and TE
    } elsif ($mode[-1] < 0) {
      ;
    } else {
      #s/^(\.\s*)(na|hy\s+0)$/${1}if n .$2/;
      #s/^(\.\s*)(na)$/${1}if n .$2/;
      $self->tweak($mode[-1] // 0) unless /^[.]/ || $stop_tweaking;
    }
    $self->puts();
  }
}


sub pua {
  my ($self) = @_;
  $self->{pua} //= 0xF0000;
  pack "U*", $self->{pua}++;
}


sub puts {
  my $self = shift;
  if (@_) {
    $self->puts() for @_;
  } else {
    my $NR = $self->nr;
    my $sp = '(?:'.join('|', keys %{$self->{sp}}).')';
    my @lines = split /\n/;
    @lines = "" unless @lines;
    for (@lines) {
      if (s/$sp/$self->{sp}{$&}/g) {
        my @line = split /\n/;
        if (@line > 1) {
          my @out;
          for (@line) {
            push @out, ".lf $NR" if /^[^.]/;
            push @out, $_;
          }
          $_ = join "\n", @out;
        }
      }
      conv() if $self->{use_conv};
      say;
      $NR++;
    }
  }
}


sub tweak {
  my ($self, $m) = @_;

  my $lp = $self->rc_regex('opening_brackets');
  my $rp = $self->rc_regex('closing_brackets');
  my $pm = $self->rc_regex('dividing_punctuation_marks');
  my $md = $self->rc_regex('middle_dots');
  my $es = $self->rc_regex('full_stops');
  my $sb = $self->rc_regex('commas');
  my $ja = $self->rc_regex('chars_japanese');
  my $ns = $self->rc_regex('chars_not_starting');
  my $ne = $self->rc_regex('chars_not_ending');

  my $dnl = $self->rc_regex('dnl');
  my $vdnl = $self->rc('vdnl');

  if ($m & 1) {
    # 1. put a half-space or a quarter-space before and after
    # punctuation marks
    #s/($lp)/$self->{hwsp}$1/g;              # before opening_brackets
    s/($es|$pm|$sb|$rp)/$1$self->{hwsp}/g;  # after closing_brackets, ...
    s/($md)/$self->{qwsp}$1$self->{qwsp}/g; # before and after

    # before opening_brackets
    s/($ja)($dnl\n)($lp)/$1$self->{hwsp}$2$3/g;
    $self->{bob} ||= $self->pua;
    s/($lp)/$self->{bob}$1/g;
    s/(\\[\*\$a-zA-Z]?)$self->{bob}($lp)/$1$2/g; # groff 2char esc
    s/$self->{bob}/$self->{hwsp}/g;

    # 2. remove spaces between punctuations
    s/($lp)$self->{hwsp}+/$1/g;             # after opening_brackets
    s/$self->{hwsp}+($es|$pm|$sb|$rp)/$1/g; # before closing_brackets, ...
  }

  if ($m & 2) {
    # 3. insert stretchable zero-width space between japanese
    # characters (mode 2, 3)
    s/$ja$ja+/join $self->{zwsp}, split m(), $&/eg;
  }

  if (($m & 3) == 1) {
    # 4a. remove newline between Japanese characters, and insert \:
    s/($ja$dnl\n)($ja)/$1\\:$2/g;
  } elsif ($m & 2) {
    # 4b. use ZWSP instead of \: above.
    s/($ja$dnl\n)($ja)/$1$self->{zwsp}$2/g;
  } else {
    if ($m & 8) {
      s/($dnl\n)/$vdnl$1/g;
    }
  }

  # 5. replace breakable space to unbreakable space to restrict
  # characters placed at the staring and ending
  my $sp = '(?:'.join('|', keys %{$self->{sp}}).')';
  s/($sp)($ns)/$self->{nbsp}{$1}$2/g;       # not starting line
  s/($ne)($sp)/$1$self->{nbsp}{$2}/g;       # not ending line

  # 6. remove spaces at starting and ending line XXXXX
  #s/^$sp+//g;
  #s/$sp+$//g;

  # 7. if multiple spaces are connected, ...
  my $hwsp = qr/[$self->{hwsp}$self->{hwnbsp}]/;
  my $qwsp = qr/[$self->{qwsp}$self->{qwnbsp}]/;
  my $zwsp = qr/[$self->{zwsp}$self->{zwnbsp}]/;
  s/$hwsp*($qwsp|$zwsp)+$hwsp*/$1/g;
  s/($hwsp)+/$1/g;

  # 8. if the zero-width space is aligned with the user-entered space, ...
  my $groffspace = qr/\s|\\(?:[\x{20}0|^&)\/,~:]|h(?:'[^']*'|\[[^\]]*\]))/;
  s/$self->{hwsp}+($groffspace)/$1/g;
  s/($groffspace)$self->{hwsp}+/$1/g;

  if ($m & 8) {
    # 9. make spaces visible
    my $vsp = '(?:'.join('|', keys %{$self->{vsp}}).')';
    s/$vsp/$self->{vsp}{$&}/g;   # xxxxx
  }
}

sub getline {
  my ($self, $mode) = @_;
  my $ja = $self->rc_regex('chars_japanese');
  my $dnl = $self->rc('dnl');
  my @t;
  while (1) {
    unless (defined $self->unget()) {
      last unless defined ($_ = <>);
      chomp;
      unconv() if $self->{use_conv};
    }
    return wantarray? ($_, $self->nr) : $_ if $mode < 0;
    if (@t) {
      if ($t[-1] =~ /\\$/) {
        push @t, $_;
        next;
      }
      if ($t[-1] =~ /$ja$/ && /^$ja/) {
        $t[-1] .= $dnl;
        push @t, $_;
        next;
      }
      $self->unget($_);
      $self->nr(-@t);
      $_ = join "\n", @t;
      return wantarray? ($_, $self->nr) : $_;
    }
    $. = $1 - 1 if /^\.\s*lf\s+(\d+)/;
    if (/^[^.]/ || /\\$/) {
      push @t, $_;
    } else {
      return wantarray? ($_, $self->nr) : $_;
    }
  }
  if (@t) {
    $self->nr(-@t);
    $_ = join "\n", @t;
    return wantarray? ($_, $self->nr) : $_;
  }
  $_ = undef;
  return wantarray? ($_, $self->nr) : $_;
}


sub unget {
  my $self = shift;
  $self->{unget} //= [];
  if (@_) {
    push @{$self->{unget}}, @_;
  } else {
    $_ = shift @{$self->{unget}};
  }
}


sub nr {
  my $self = shift;
  $self->{nr} = $.;
  $self->{nr} += -@{$self->{unget} // []};
  $self->{nr} += shift if @_;
  $self->{nr};
}


sub conv {
  if (__PACKAGE__->can('NFD')) {
    s/[^[:ascii:]]/
      my @u = unpack "U*", NFD($&);
      sprintf "\\[u".join('_', ("%04X") x @u)."]", @u;
    /eg;
  } else {
    s/[^[:ascii:]]/sprintf "\\[u%04X]", unpack "U*", $&/eg;
  }
}


sub unconv {
  if (__PACKAGE__->can('NFC')) {
    s/\\\[u([0-9A-F_]+)\]/NFC(join '', map { pack "U", hex } split '_', $1)/eg;
  } else {
    s/\\\[u([0-9A-F]+)\]/pack "U", hex $1/eg;
  }
}


sub rc_regex {
  my ($self, $keyword) = @_;
  my @list = map { s/[\`\'\"\*\.\\\(\)\{\}]|(?:^[\[\]]$)/\\$&/g; $_; } $self->rc($keyword);
  @list ? "(?:" . join('|', @list) . ")" : undef;
}


sub rc {
  my $self = shift;
  $self->{rc} //= loadrc();
  my $me = basename($0, '.pl');
  my @list = map flatten(
    eval(join '->', '$self', map "{'$_'}", 'rc', $me, split /[.]/) //
    eval(join '->', '$self', map "{'$_'}", 'rc', split /[.]/)), @_;
  wantarray ? @list : join '', @list;
}


sub flatten {
  my @list;
  my %seen;
  for (@_) {
    if (ref) {
      die "rc: ?HASH" unless ref eq 'ARRAY';
      push @list, grep !$seen{$_}++, flatten(@$_);
    } elsif (defined) {
      unconv();
      push @list, grep !$seen{$_}++, $_;
    }
  }
  @list;
}


sub loadrc {
  my @rcdir;
  push @rcdir, split /:/ for grep defined,
    $ENV{GROFF_TMAC_PATH},
    catdir(rootdir, qw/usr local share groff site-tmac/),
    catdir(rootdir, qw/usr share groff site-tmac/),
    catdir(rootdir, qw/usr local etc groff/),
    catdir(rootdir, qw/etc groff/);
  unshift @rcdir, '.' if defined $ENV{DEBUG};
  my $rcname = basename($0, '.pl').'.rc';
  my ($rcfile) = grep -f,
    (map catfile($_, ".$rcname"), $ENV{HOME}),
    (map catfile($_, $rcname), @rcdir);
  my $rc;
  if ($rcfile) {
    open my $fd, "<:utf8", $rcfile or die "$0: can't open $rcfile";
    (my $content = do { local $/ = undef; <$fd> }) =~ s/\s*\#.*$//mg;
    $rc = Load($content);
  }
  die "$0: can't load $rcname" unless $rc;
  $rc;
}

__PACKAGE__->run;
