include use-groff.mk

VPATH=	${UG}/files/${OS} ${UG}/files

setup::

all::	inc-Module-Install.cpanm

clean::
	rm -f inc-Module-Install.cpanm

Perldoc-Server?=	https://github.com/obuk/Perldoc-Server.git
HTML-Spacing-JA?=	https://github.com/obuk/HTML-Spacing-JA.git

all::

install::	Perldoc-Server.stamp

Perldoc-Server.stamp:	mandoc.pkg nkf.pkg HTML-Spacing-JA.cpanm Pod-Man-TMAC.cpanm
	[ -d $* ] || git clone ${$*}
	#cd $*; cpanm --installdeps .; perl Makefile.PL
	#cd $*; make; make install
	bash -l -c 'cd $(abspath $*); cpanm --installdeps .; perl Makefile.PL'
	bash -l -c 'cd $(abspath $*); make; make install'
	@echo '# cd $*'
	@echo '# perldoc-server --perl `which perl` # or'
	@echo '# env PERL5LIB=./lib plackup --port 3000 -R ./lib script/perldoc_server.psgi'

POD2?=	$(shell perl -MPOD2::Base -MFile::Basename -e 'print dirname($$INC{"POD2/Base.pm"}), "\n"')

INSTALL_PODS_POD2JA?=	\
	xargs env INSTALL="ln -sf" \
	$(shell pwd)/files/install-pod.pl -L JA $(TWIST_NAMES) | sh

TWIST_NAMES+=	-t 5.6.1/perlop.pod=perlop
TWIST_NAMES+=	-t AnyData-0.05/AnyData/Format/HTMLtable.pod=AnyData::Format::HTMLtable
TWIST_NAMES+=	-t AnyData-0.05/AnyData/Format/Passwd.pod=AnyData::Format::Passwd
TWIST_NAMES+=	-t CGI-Session-3.11/Tutorial.pod=CGI::Session::Tutorial
TWIST_NAMES+=	-t CGI-SpeedyCGI-2.21/SpeedyCGI.pod=CGI::SpeedyCGI
TWIST_NAMES+=	-t Crypt-IDEA-1.01/IDEA.pod=Crypt::IDEA
#TWIST_NAMES+=	-t Crypt-PasswdMD5-1.2/PasswdMD5.pod=Crypt::PasswdMD5::unix_md5_crypt
TWIST_NAMES+=	-t DBD-mysql-2.1026/Mysql.pod=DBD::mysql,DBD::mSQL
TWIST_NAMES+=	-t DBD-mysql-2.1026/DBD/mysql/INSTALL.pod=DBD::mysql::INSTALL
TWIST_NAMES+=	-t DBD-Oracle-1.14/README.hpux.pod=DBD::Oracle::README.hpux
TWIST_NAMES+=	-t DBD-Oracle-1.14/ora_explain.pod=DBD::Oracle::explain,ora_explain
TWIST_NAMES+=	-t DBD-Sybase-1.00/dbd-sybase.pod=DBD::Sybase
TWIST_NAMES+=	-t Digest-1.00/Digest.pod=Digest
TWIST_NAMES+=	-t File-Slurp-9999.01/extras/slurp_article.pod=slurp_article
TWIST_NAMES+=	-t Furl-0.24/lib/Furl/Response.pod=Furl::Response
TWIST_NAMES+=	-t HTML-Lint-1.22/lib/Test/HTML/Lint.pod=Test::HTML::Lint
TWIST_NAMES+=	-t HTML-Lint-1.22/lib/HTML/Lint/HTML4.pod=HTML::Lint::HTML4
TWIST_NAMES+=	-t Inline-0.43/C/C-Cookbook.pod=Inline::C::Cookbook
TWIST_NAMES+=	-t URI-1.35/URI/Heuristic.pod=URI::Heuristic

install-pods-deps:	POD2-Base.cpanm common-sense.cpanm Perl6-Slurp.cpanm \
			Pod-POM.cpanm

install-pods::	install-pods-jprp-docs
install-pods-jprp-docs:	pods/jprp.stamp install-pods-deps
	cd pods/jprp/docs/perl; \
	find . -name '*.pod' | $(INSTALL_PODS_POD2JA)
	cd pods/jprp/docs/modules; \
	find . -name '*.pod' | $(INSTALL_PODS_POD2JA)

install-pods::	install-pods-moose-doc-ja
install-pods-moose-doc-ja:	pods/Moose-Doc-JA.stamp install-pods-deps
	cd pods/Moose-Doc-JA/Moose; \
	find . -name '*.pod' | $(INSTALL_PODS_POD2JA)

install-pods::	install-pods-module-pod-jp
install-pods-module-pod-jp:	pods/module-pod-jp.stamp install-pods-deps
	cd pods/module-pod-jp/docs/modules; \
	find . -name '*.pod' | $(INSTALL_PODS_POD2JA)

#JPRP?=	:pserver:anonymous@cvs.sourceforge.jp:/cvsroot/perldocjp
JPRP?=	:pserver:anonymous@cvs.osdn.jp:/cvsroot/perldocjp
PODJP?=	https://github.com/perldoc-jp/module-pod-jp
DOCJP?=	https://github.com/jpa/Moose-Doc-JA

pods:	pods/jprp.stamp pods/module-pod-jp.stamp \
	pods/Moose-Doc-JA.stamp

pods/jprp.stamp:	cvs.pkg
	test -d $* || mkdir -p $*
	test -d $*/docs || (cd $*; cvs -q -d $(JPRP) co docs)
	cd $*/docs; cvs -q update
	touch $@

pods/module-pod-jp.stamp:	git.pkg
	test -d $* || git clone $(PODJP) $*
	cd $*; git pull
	touch $@

pods/Moose-Doc-JA.stamp:	git.pkg
	test -d $* || git clone $(DOCJP) $*
	cd $*; git pull
	touch $@

