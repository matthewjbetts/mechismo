#!/usr/bin/perl -w

use strict;
use warnings;
use Getopt::Long;
use Dir::Self;
use Config::General;
use Fist::Schema;

# options
my $help;

# other variables
my $conf;
my $config;
my $schema;
my $in;
my $rs_aliases;
my $acc;
my $seq;
my $alias;
my $gnString;
my $keyValuePair;
my $type;
my $namesString;
my $name;

# parse command line
GetOptions(
	   'help'            => \$help,
          );

defined($help) and usage();

sub usage {
    my($msg) = @_;

    my $prog;
    my $usage;

    ($prog = __FILE__) =~ s/.*\///;

    defined($msg) and warn("\nUsage problem: $msg\n");

    $usage = <<END;

Usage: $prog [options] < uniprot.txt

option                 parameter  description                                               default
---------------------  ---------  ---------------- ---------------------------------------  -------
--help                 [none]     print this usage info and exit

END

    die $usage;
}

$conf = Config::General->new(__DIR__ . "/../fist.conf");
%{$config} = $conf->getall;
$schema = Fist::Schema->connect($config->{"Model::FistDB"}->{connect_info}->{dsn}, $config->{"Model::FistDB"}->{connect_info}->{user}, $config->{"Model::FistDB"}->{connect_info}->{password});

$rs_aliases = $schema->resultset('Alias');

$gnString = '';
while(<STDIN>) {
    if(/^AC   (\S+)/) {
        defined($acc) and next;
        $acc = $1;
        $acc =~ s/;.*//;
    }
    elsif(s/^GN   //) {
        chomp;
        $gnString .= $_;
    }
    elsif(/^\/{2}/) {
        print "HERE: '$acc'\n";
        if(defined($seq = $schema->resultset('Seq')->find({primary_id => $acc}))) {
            print "HERE\n";

            $gnString =~ s/\s*\{.*?\}//g;
            foreach $keyValuePair (split /\s*;\s*/, $gnString) {
                if($keyValuePair =~ /\A(.*?)=(.*)/) {
                    ($type, $namesString) = ($1, $2);
                    foreach $name (split /,/, $namesString) {
                        $name = truncateString($name, 20);
                        print join("\t", 'UPDATE', $seq->id, $acc, $seq->name, $name, $type), "\n";
                        $alias = $rs_aliases->find_or_create({id_seq => $seq->id, alias => $name, type => $type});
                        ($seq->name eq 'unknown_id') and $seq->name($name);
                    }
                }
                else {
                    warn "Error: cannot parse $acc '$keyValuePair'.";
                }
            }
            $seq->update();
        }

        $acc = undef;
        $gnString = '';
    }
}

sub truncateString {
    my($string, $toLength) = @_;

    # FIXME - this was adapted from Fist/Utils/Search.pm - put it somewhere central

    my $length;
    my $truncatedString;

    $length = length $string;
    $truncatedString = ($length > $toLength) ? (substr($string, 0, $toLength - 3) . '...') : $string;

    return $truncatedString;
}
