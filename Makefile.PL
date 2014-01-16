use 5.012004;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Finance::CoinBase',
    VERSION_FROM      => 'lib/Finance/CoinBase.pm', # finds $VERSION
    PREREQ_PM         => {
	    'JSON' => 0,
	    'LWP::UserAgent' => 0,
	    'Mozilla::CA' => 0,
	    'Carp' => 0,
	    'Digest::SHA' => 0,
	    'WWW::Mechanize' => 0,
	}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Finance/CoinBase.pm', # retrieve abstract from module
       AUTHOR         => 'Todd T. Fries <todd@fries.net>') : ()),
);
