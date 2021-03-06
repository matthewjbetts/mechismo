#!/usr/bin/env perl
# IMPORTANT: if you delete this file your app will not work as
# expected.  You have been warned.
use inc::Module::Install;
use Module::Install::Catalyst; # Complain loudly if you don't have
                               # Catalyst::Devel installed or haven't said
                               # 'make dist' to create a standalone tarball.

name 'Fist';
all_from 'lib/Fist.pm';

requires 'Catalyst::Runtime' => '5.90001';
requires 'Catalyst::Plugin::ConfigLoader';
requires 'Catalyst::Plugin::Static::Simple';
requires 'Catalyst::Action::RenderView';
requires 'Moose';
requires 'namespace::autoclean';
requires 'Config::General'; # This should reflect the config file format you've chosen
                            # See Catalyst::Plugin::ConfigLoader for supported formats

requires 'Catalyst::View::TT';
requires 'Catalyst::View::JSON';

###### mechismo-specific requirements (as opposed to those for catalyst) ######
requires 'PerlIO::gzip';
requires 'MooseX::MarkAsMethods';
requires 'MooseX::NonMoose';
requires 'DBIx::Class';
requires 'CHI';
requires 'Dir::Self';
requires 'Net::IPAddress';
requires 'String::Escape';
requires 'DateTime::Format::ISO8601';
requires 'Net::OpenSSH';
###############################################################################

test_requires 'Test::More' => '0.88';
tests_recursive();

catalyst_ignore('.*~\Z');
catalyst_ignore('.*\.o\Z');
catalyst_ignore('data');
catalyst_ignore('root');
catalyst_ignore('lib');
catalyst_ignore('c');
catalyst;

install_script glob('script/*.pl');
auto_install;
WriteAll;
