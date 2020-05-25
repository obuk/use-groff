#!/usr/bin/env perl
use strict;
use warnings;
use Mojolicious::Lite;
use URI::Escape qw(uri_escape_utf8 uri_unescape);
use File::Path qw(make_path);
use File::Spec::Functions;
use File::Basename;
use Encode;
use utf8;

binmode STDERR, ":utf8";

plugin('Config');

get '/' => sub {
  my $c = shift;
  $c->render(template => 'index');
};

get '/man/#name' => sub {
  my $c = shift;
  my $name = $c->stash('name');
  warn "# name = $name\n";
  my (undef, $sect, $lang) = man_where($c, $name);
  if ($sect) {
    $c->redirect_to("/man/$sect/$name");
  } else {
    $c->reply->not_found;
  }
};

get '/man/:sect/#name' => sub {
  my $c = shift;
  my $name = $c->stash('name');
  my ($src, $sect, $lang) = man_where($c, $name, $c->stash('sect'));
  my $cache = $c->app->config('cache') || '.cache';
  my $dest = catfile grep defined, $cache, $lang, $sect, $name;
  make_path dirname $dest;
  if (! -f $dest || $c->app->config('force')) {
    if ($src) {
      my $cat = $src =~ /\.gz$/? "zcat" : "cat";
      $cat = "$cat $src";
      my $iconv;
      $iconv = $c->app->config("iconv_$lang") if $lang;
      $iconv //= $c->app->config("iconv");
      $cat = "$cat | $iconv" if $iconv;
      my @lines;
      if (open my ($fd), "-|:utf8", $cat) {
	@lines = <$fd>;
	close $fd;
      }
      my $fixes;
      $fixes = $c->app->config("fixes_$lang") if $lang;
      $fixes //= $c->app->config("fixes");
      &{$fixes}(\@lines) if $fixes;
      add_links($c, "/man", \@lines);
      my $groff = $c->app->config("groff_$lang") if $lang;
      $groff //= $c->app->config("groff");
      my $gs = $c->app->config("gs_$lang") if $lang;
      $gs //= $c->app->config("gs");
      my $groff_gs = $gs ? "$groff | $gs" : $groff;
      warn "# $cat | $groff_gs\n";
      if (open my ($fd), "|-:utf8", "tee $dest.t | $groff_gs > $dest") {
	print {$fd} @lines;
	print {$fd} ".pdfview /PageMode /UseOutlines\n";
	close $fd;
      }
    }
  }
  if (-f $dest) {
    my $pdf = `cat $dest`;
    $c->render(data => $pdf, format => 'pdf');
  } else {
    $c->reply->not_found;
  }
};

sub man_where {
  my ($c, $name, $sect) = @_;
  my $lang = $c->param('lang') // $c->app->config('lang');
  $lang = '' if $lang && $lang eq 'en';
  $sect //= '';
  my $man = "man -w" . ($lang ? " -L$lang" : "");
  chop(my $where = `$man $sect $name`);
  if ($lang) {
    if ($where =~ m{(?:/($lang))?/man(\w+)/}) {
      ($sect, $lang) = ($2, $1);
    }
  } else {
    if ($where =~ m{/man(\w+)/}) {
      $sect = $1;
    }
  }
  unless ($where) {
    if ($name =~ /issues/) {
      if (my $issues = $c->app->config('issues')) {
        if (-f $issues) {
          $where = $issues;
          $sect = $sect || 7;
          $lang = 'ja';
        }
      }
    }
  }
  ($where, $sect, $lang);
}

sub parse_args {
  my $req = shift;
  if (@_) {
    local $_ = shift;
    s/\\".*//;
    my @args;
    while (s/^\s*"((?>(?:(?>[^"\\]+)|\\.)*))"|((?>\\.|\S)+)//x) {
      push @args, grep defined, $1, $2;
    }
    if ($req =~ /^(SH|SS)$/) {
      my $text = shift @args;
      while (@args && $args[0] !~ /^[[:punct:]]/) {
        $text .= " " . shift @args;
      }
      unshift @args, $text;
    } elsif ($req =~ /^(Sh|Ss|Sx|Sy|Tn)$/) {
      my $text = shift @args;
      my $pend;
      while (@args && $args[0] !~ /^[[:punct:]]/) {
        if ($args[0] eq 'Ns') {
          $pend = shift @args;
        } elsif ($args[0] =~ /^[A-Z][a-z]{1,2}$/) {
          last;
        } else {
          $text .= " " if !($pend && $pend eq 'Ns');
          $text .= shift @args;
          $pend = '';
        }
      }
      unshift @args, $text;
    }
    return ($req, @args);
  }
  $req;
}

sub pdfhref {
  my $f = shift;
  my %x;
  while (@_ && $_[0] =~ /^-/) {
    my $opt = shift;
    last if $opt eq '--';
    $x{$opt} = shift;
  }

  defined $x{-D} and $x{-D} =~ s/\\[:&%]//g;
  defined $x{-D} and $x{-D} =~ s/\\([-])/$1/g;
  defined $x{-P} and $x{-P} =~ s/\\m(?:[^\(\[]|[(]..|[\[][^\]]*[\]])//g;
  defined $x{-A} and $x{-A} =~ s/\\m(?:[^\(\[]|[(]..|[\[][^\]]*[\]])//g;

  my $ja = qr/[\x{3041}-\x{3096}\x{30A0}-\x{30FF}\x{4E00}-\x{9FFF}]/;
  my $text = "@_";
  $text =~ s/([\/#\-])(\w)/$1\\:$2/g;
  $text =~ s/(\.)(\w)/\\&$1$2/g;
  $text =~ s/($ja)($ja)/$1\\:$2/g;

  if (uc($f) eq 'W') {
    return join " ", ".pdfhref", uc($f),
      (map { $x{$_} ? ($_, $x{$_}) : () } qw/-D -P -A/), '--',
      $text;
  }
  if (uc($f) eq 'L') {
    return join " ", ".pdfhref", uc($f),
      (map { $x{$_} ? ($_, $x{$_}) : () } qw/-D -P -A/),
      (grep defined $x{$_}, qw/-X/), '--',
      $text;
  }
  if (uc($f) eq 'M') {
    return join " ", ".pdfhref", uc($f),
      (map { $x{$_} ? ($_, $x{$_}) : () } qw/-N/),
      (grep defined $x{$_}, qw/-X -E/),
      "\n";
  }
  if (uc($f) eq 'O') {
    return join " ", ".pdfhref", uc($f),
      "@_";
  }
  return "";

}

sub add_links {
  my $c = shift;
  my $me = $c->url_for(shift)->to_abs;
  my $lines = shift;

  my %tag;
  for (@$lines) {
    if (/^[.]\s*(SH|SS|Sh|Ss)\s+(.*)$/) {
      my ($req, $text, @args) = parse_args($1, $2);
      if ($text) {
        $tag{$text} = uri_escape_utf8($text);
        $tag{$text} =~ s/%20/-/g;
        $tag{$text} =~ tr[()\[\]<>{}\/%][.];
      }
    }
  }

  my $re_pre = qr/(?:[<]|\\[fm*](?:[^\(\[]|[(]..|\[[^\]]*\]))+/;
  my $re_aff = qr/(?:[>]|\\[fm*](?:[^\(\[]|[(]..|\[[^\]]*\])|\\\|)+[,.]?/;
  my $re_name = qr/(?:\\%)?\w+(?:\\?-|[.\w])*/;
  my $re_sect = qr/\d\w*/;

  my @ur;
  for (@$lines) {
    if (/^.\s*\\"/) {
      ;
    } elsif (/^\.\s*(de1?|dei1?|am1?|ami1?|ig)\b/ .. /^\.\./) {  # groff(7)
      ;
    } elsif (/^\.\s*UR/ ... /^\.\s*UE/) {
      if (/^\.\s*UR\s+(.*?)\s*$/) {
        @ur = ($1);
        chomp($ur[-1]);
        s/^/.\\" /;
      } elsif (/^\.\s*UE\s+(.*?)\s*$/) {
	my ($dest, $aff) = (shift(@ur), $1);
        s/^/.\\" /;
        (my $text = $dest) =~ s/^$me\/?//;
        $text = decode("utf8", uri_unescape($text));
        if ($aff) {
          if ($aff !~ /^[[:punct:]]/) {
            $aff = "\\ $aff";
          }
        } else {
          $aff = "";
        }
        $aff = "\\*(ra$aff";
        my $pre = "\\*(la";
        unless ($dest =~ m{^\w+://}) {
          $dest = "http://$dest";
        }
	$_ .= pdfhref 'W', -D => $dest, -P => $pre, -A => $aff, '--',
	  "$text\n";
      }
    } elsif (/^\.\s*(Xr)\s+(.*)$/) {
      my ($req, $name, @args) = parse_args($1, $2);
      my $sect = shift @args if @args && $args[0] =~ /^\d++\w?+$/;
      my $aff = "@args" if @args;
      my $dest = $sect? "$me/$sect/$name" : "$me/$name";
      s/^/.\\" /;
      $_ .= pdfhref 'W', -D => $dest, -A => $aff, '--',
        "\\fB$name\\fR" . ($sect ? "($sect)" : "" ) . "\n";

    } elsif (/^\.\s*(Sh|Ss|SH|SS)\s+(.*)$/) {
      my ($req, $text, @args) = parse_args($1, $2);
      $_ .= pdfhref 'O', 1, "$text\n" if $req =~ /Sh/i;
      $_ .= pdfhref 'O', 2, "$text\n" if $req =~ /Ss/i;
      if (my $tag = $tag{$text}) {
	$_ .= pdfhref 'M', -N => $tag;
      }

    } elsif (/^\.\s*(S[xy]|Tn)\s+(.*)$/) {
      my ($req, $text, @args) = parse_args($1, $2);
      my ($aff, $pre);
      if (@args) {
        $aff = "@args"; @args = ();
      }
      if (my $tag = $tag{$text}) {
        s/^/.\\" /;
        $_ .= pdfhref 'L', -D => $tag, -P => $pre, -A => $aff, '--',
	  "\\fB$text\\fR\n";
      } elsif ($text =~ /^(?:\\%)?\w/ && $aff && $aff =~ s/[(](\d\w*)[)]//) {
	my ($name, $sect) = ($text, $1);
	my $dest = "$me/$sect/$name";
	$_ .= pdfhref 'W', -D => $dest, -P => $pre, -A => $aff, '--',
	  "\\fB$name\\fR($sect)\n";
      } elsif ($text =~ s/($re_pre)?((?:https?|ftp):\/\/\S+)($re_aff)?\s*//) {
	my ($pre, $dest, $aff) = ($1, $2, $3);
	s/^/.\\" /;
	$_ .= pdfhref 'W', -D => $dest, -P => $pre, -A => $aff, '--',
	  "\\fB$dest\\fR\n";
	$_ .= $text . "\n" if $text;
      }

    } elsif (/^\.\s*(B|I)\s+(.*)$/) { # and SM, SB
      my ($req, @args) = parse_args($1, $2);
      my $text = "@args";       # xxxxx
      my $fn = $req;
      if ($text =~ s/^($re_pre)?((?:https?|ftp):\/\/\S+)($re_aff)?\s*//) {
        my ($pre, $dest, $aff) = ($1, $2, $3);
        s/^/.\\" /;
        $_ .= pdfhref 'W', -D => $dest, -P => $pre, -A => $aff, '--',
          "\\f$fn$dest\\fP\n";
        $_ .= $text . "\n" if $text;
      } else {
        if (my $tag = $tag{$text}) {
          s/^/.\\" /;
          $_ .= pdfhref 'L', -D => $tag,
            '--',
            "\\f$fn$text\\fP\n";
        }
      }

    } elsif (/^\./ && /\.\s*(BI|BR|IB|IR|RB|RI)\s+(.*)$/) {
      my ($req, @args) = parse_args($1, $2);
      my @fnts = map substr($req, $_ % 2, 1), 0 .. $#args;
      my $save = $_;
      s/^/.\\" /;
      while (@args) {
	my ($text, $fn) = (shift @args, shift @fnts);
	if ($text =~ /^(?:\\%)?\w/ &&
	    @args && $args[0] =~ s/^[(](\d\w*)[)](\S*)\s*//) {
	  my ($name, $sect, $aff) = ($text, $1, $2);
	  my $dest = "$me/$sect/$name";
	  $_ .= pdfhref 'W', -D => $dest, -A => $aff, '--',
	    "\\f$fn$name\\fP\\f$fnts[0]($sect)\\fP\n";
	  $_ .= $args[0] . "\n" if $args[0];
	  shift @args; shift @fnts;
	} elsif ($text =~ s/^($re_pre)?((?:https?|ftp):\/\/\S+)($re_aff)?\s*//) {
	  my ($pre, $dest, $aff) = ($1, $2, $3);
	  $_ .= pdfhref 'W', -D => $dest, -P => $pre, -A => $aff, '--',
	    "\\f$fn$dest\\fP\n";
	  $_ .= $text . "\n" if $text;
	} else {
          if (my $tag = $tag{$text}) {
            $_ .= pdfhref 'L', -D => $tag,
              (@args ? (-A => "\\c") : ()),
              '--',
              "\\f$fn$text\\fP\n";
          } else {
            #s/\\c\n$//s;
            $_ .= "\\f$fn$text\\fP".
              (@args ? "\\c" : "").
              "\n";
          }
        }
      }
      if (/^\.pdfhref\b/m) {
	s/\\c\n$/\n/s;
      } else {
	$_ = $save;
      }

    } elsif (/^\.\s*TS/ ... /^\.\s*TE/) {
      ;

    } elsif (/^\./) {
      ;

    } else {

      s{(.*?)($re_pre)($re_name)($re_aff)[(]($re_sect)[)](\S*)\s*}{
	my ($left, $fb, $name, $fr, $sect, $aff) = ($1, $2, $3, $4, $5, $6);
        ($left ? "$left\\c\n" : "").
	  pdfhref 'W', -D => "$me/$sect/$name", -A => $aff, "--",
	  "$fb$name$fr($sect)\n"
	}ge;

      s{(.*?)($re_pre)($re_name)[(]($re_sect)[)]($re_aff)(\S*)\s*}{
	my ($left, $fb, $name, $sect, $fr, $aff) = ($1, $2, $3, $4, $5, $6);
        ($left ? "$left\\c\n" : "").
	  pdfhref 'W', -D => "$me/$sect/$name", -A => $aff, "--",
	  "$fb$name$fr($sect)\n"
	}ge;

      s{(.*?)($re_pre)((?:https?|ftp)://\S*)\s*}{
	my ($left, $pre, $dest) = ($1, $2, $3); $dest =~ s/\\[:&%]//g;
	my $aff;
        if ($pre) {
          $aff = do { $dest =~ s/$re_aff$//g ? $& : '' }
            ||   do { $dest =~ s/$re_aff.*$//g ? $& : '' };
        }
	($left ? "$left\\c\n" : "").
	  pdfhref 'W', -D => $dest, -P => $pre, -A => $aff, '--',
	  "\\fB$dest\\fR\n";
      }ge;

    }

  }
}

app->start;

__DATA__

@@ index.html.ep
% layout 'default';
% title 'pdfman';
<h3>pdfman</h3>
Examples of URLs are:
<ul>
  <li> groff(1) - <a href="<%= $c->url_for('/man')->to_abs %>/groff"
    ><%=$c->url_for('/man')->to_abs %>/groff</a></li>
  <li> groff(7) - <a href="<%= $c->url_for('/man')->to_abs %>/7/groff"
    ><%=$c->url_for('/man')->to_abs %>/7/groff</a></li>
</ul>

@@ not_found.html.ep
% layout 'default';
% title 'not found';
<h3><%= url_for() %>: not found</h3>
