#!/bin/sh -ue

if [ ! -d ~/.plenv ]; then
    git clone git://github.com/tokuhirom/plenv.git ~/.plenv
fi
if [ ! -d ~/.plenv/plugins/perl-build ]; then
    git clone git://github.com/tokuhirom/Perl-Build.git \
	~/.plenv/plugins/perl-build/
fi

xplenv() {
    bash -l -c "plenv $*"
}

if ! xplenv >/dev/null 2>/dev/null; then
    echo 'export PATH="$HOME/.plenv/bin:$PATH"' >> ~/.profile
    echo 'eval "$(plenv init -)"' >> ~/.profile
fi

if [ -n "${PERL_VERSION:-}" ]; then
    PLENV_GLOBAL="${PLENV_GLOBAL:-yes}"
elif [ -f .perl-version ]; then
    PERL_VERSION=`cat .perl-version`
    PLENV_GLOBAL="${PLENV_GLOBAL:-no}"
else
    PERL_VERSION=`perl -e 'print substr($^V, 1), "\n"'`
    PLENV_GLOBAL="${PLENV_GLOBAL:-yes}"
fi
if ! xplenv versions |grep "$PERL_VERSION"; then
    xplenv install $PERL_VERSION
fi
case "$PLENV_GLOBAL" in
    yes) xplenv global $PERL_VERSION
esac
#xplenv install-cpanm
