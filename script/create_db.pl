#!/usr/bin/perl -w

use strict;
use warnings;
use Getopt::Long;
use Config::General;
use Term::ReadKey;
use DBI;

# options
my $help;
my $user_default = $ENV{USER};  # username and password for user with permission to create db and another user
my $user = $user_default;
my $pass;
my $force;

# other variables
my $dbuser; # username and password for the specific db
my $dbpass;
my $dbi;
my $dbhost;
my $dbname;
my $dbdomain;
my $fn_conf;
my $conf;
my $config;
my $dbh;
my @cmds;
my $cmd;

# parse command line
GetOptions(
	   'help'   => \$help,
           'user=s' => \$user,
           'pass=s' => \$pass,
           'force'  => \$force,
	  );

defined($help) and usage();
defined($fn_conf = shift @ARGV) or usage();
(@ARGV == 0) or usage();

sub usage {
    my($msg) = @_;

    my $prog;
    my $usage;

    ($prog = __FILE__) =~ s/.*\///;

    defined($msg) and warn("\nUsage problem: $msg\n");

    $usage = <<END;

Usage: $prog [options] conffile < schema.sql

option   parameter  description                              default
-------  ---------  ---------------------------------------  -------
--help   [none]     print this usage info and exit
--user   string     mysql user with permission to create db  $user_default
--pass   string     password for --user                      [none]
--force  [none]     overwrite database named in conffile     [fail if already exists]

END

    die $usage;
}

print ">password:\n";
ReadMode('noecho');
$pass = ReadLine(0);
chomp $pass;
ReadMode('restore');

$conf  = Config::General->new($fn_conf);
%{$config} = $conf->getall;

if($config->{'Model::FistDB'}->{connect_info}->{dsn} =~ /(.*):host=([\w\.\-]+).*dbname=(\w+)/) {
    ($dbi, $dbhost, $dbname) = ($1, $2, $3);
}
else {
    die;
}
$dbuser = $config->{'Model::FistDB'}->{connect_info}->{user};
$dbpass = $config->{'Model::FistDB'}->{connect_info}->{password};
$dbdomain = $config->{'Model::FistDB'}->{connect_info}->{domain};

defined($dbh = DBI->connect("${dbi}:host=$dbhost", $user, $pass, {'RaiseError' => 0, 'AutoCommit' => 1})) or die;
@cmds = (
         "CREATE DATABASE $dbname",
         "GRANT SELECT, INSERT, UPDATE, DELETE, LOCK TABLES, ALTER ON $dbname.* TO \"$dbuser\"@\"$dbdomain\" IDENTIFIED BY \"$dbpass\"",
         "USE $dbname",
        );
defined($force) and unshift(@cmds, "DROP DATABASE IF EXISTS $dbname");
foreach $cmd (@cmds) {
    $dbh->do($cmd) or die "Error: could not do '$cmd'.";
}
