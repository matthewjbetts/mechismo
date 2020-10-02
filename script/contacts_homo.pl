#!/usr/bin/perl -w

use strict;
use warnings;
use Getopt::Long;
use Cwd qw(abs_path getcwd);
use File::Path qw(make_path);
use Fist::Schema;
use Dir::Self;
use Config::General;

# options
my $help;

# other variables
my $conf;
my $config;
my $schema;
my $dbh;
my $query;
my $sth;
my $row;
my $fi2group;
my $homo;
my $id_contact;
my $id_frag_inst1;
my $id_frag_inst2;
my $n1;
my $n2;
my $id_group;
my $homos;

# parse command line
GetOptions('help' => \$help);

defined($help) and usage();

sub usage {
    my($msg) = @_;

    my $prog;
    my $usage;

    ($prog = __FILE__) =~ s/.*\///;

    defined($msg) and warn("\nUsage problem: $msg\n");

    $usage = <<END;

Usage: $prog [options]

option  parameter  description                     default
------  ---------  ------------------------------  -------
--help  [none]     print this usage info and exit

END

    die $usage;
}

$conf = Config::General->new(__DIR__ . "/../fist.conf");
%{$config} = $conf->getall;
$schema = Fist::Schema->connect($config->{"Model::FistDB"}->{connect_info}->{dsn}, $config->{"Model::FistDB"}->{connect_info}->{user}, $config->{"Model::FistDB"}->{connect_info}->{password});
$dbh = $schema->storage->dbh;
$query = <<END;
SELECT a.id,
       c.id
FROM   FragInst       AS a,
       FragToSeqGroup AS b,
       SeqGroup       AS c
WHERE  b.id_frag = a.id_frag
AND    c.id = b.id_group
AND    c.type  IN ('frag', 'fist lf=0.5 pcid=50.0')
END
$sth = $dbh->prepare($query);
$sth->{mysql_use_result} = 1;
$sth->execute();
$fi2group = {};
while($row = $sth->fetchrow_arrayref) {
    $fi2group->{$row->[0]}->{$row->[1]}++;
}

$sth = $dbh->prepare('SELECT id, id_frag_inst1, id_frag_inst2 FROM Contact');
$sth->{mysql_use_result} = 1;
$sth->execute();
$homos = {};
while($row = $sth->fetchrow_arrayref) {
    ($id_contact, $id_frag_inst1, $id_frag_inst2) = @{$row};
    $homo = 0;

    if(defined($fi2group->{$id_frag_inst1}) and defined($fi2group->{$id_frag_inst2})) {
        $n1 = scalar keys %{$fi2group->{$id_frag_inst1}};
        $n2 = scalar keys %{$fi2group->{$id_frag_inst2}};

        if($n1 <= $n2) {
            foreach $id_group (keys %{$fi2group->{$id_frag_inst1}}) {
                if(defined($fi2group->{$id_frag_inst2})) {
                    $homo = 1;
                    last;
                }
            }
        }
        else {
            foreach $id_group (keys %{$fi2group->{$id_frag_inst2}}) {
                if(defined($fi2group->{$id_frag_inst1})) {
                    $homo = 1;
                    last;
                }
            }
        }
    }

    print join("\t", $id_contact, $homo), "\n";
    $homos->{$id_contact} = $homo;
}


$sth = $dbh->prepare('UPDATE Contact SET homo = ? WHERE id = ?'); # FIXME - update via object
foreach $id_contact (sort {$a <=> $b} keys %{$homos}) {
    $sth->execute($homos->{$id_contact}, $id_contact);
}
