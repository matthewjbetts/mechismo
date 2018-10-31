#!/usr/bin/perl -w

use strict;
use warnings;
use Getopt::Long;
use Cwd qw(abs_path getcwd);
use File::Path qw(make_path);
use Dir::Self;
use Config::General;
use Fist::Schema;
use Fist::Utils::Overlap;

# options
my $help;
my $type;

# other variables
my $conf;
my $config;
my $schema;
my $dbh;
my $sth;
my $query;
my $row;
my $groups;
my $id_group;
my $id_frag;
my $id_seq;
my $frags;
my $frag;
my $frag_inst;

# parse command line
GetOptions(
	   'help'   => \$help,
           'type=s' => \$type,
	  );

defined($help) and usage();
defined($type) or usage();

sub usage {
    my($msg) = @_;

    my $prog;
    my $usage;

    ($prog = __FILE__) =~ s/.*\///;

    defined($msg) and warn("\nUsage problem: $msg\n");

    $usage = <<END;

Usage: $prog [options]

option    parameter  description                     default
--------  --------- -------------------------------  -------
--help    [none]     print this usage info and exit
--type    string     type of fragment seq group

END

    die $usage;
}

$conf = Config::General->new(__DIR__ . "/../fist.conf");
%{$config} = $conf->getall;
$schema = Fist::Schema->connect($config->{"Model::FistDB"}->{connect_info}->{dsn}, $config->{"Model::FistDB"}->{connect_info}->{user}, $config->{"Model::FistDB"}->{connect_info}->{password});
$dbh = $schema->storage->dbh;

$frags = {};
$query = 'SELECT f.id, f.idcode, f.dom FROM Frag AS f';
$sth = $dbh->prepare($query);
$sth->execute;
while($row = $sth->fetchrow_arrayref) {
    $frags->{$row->[0]} = {id => $row->[0], idcode => $row->[1], dom => $row->[2]};
}

$query = 'SELECT fi.id, fi.assembly, fi.model, fi.id_frag FROM FragInst AS fi';
$sth = $dbh->prepare($query);
$sth->execute;
while($row = $sth->fetchrow_arrayref) {
    $frags->{$row->[3]}->{frag_insts}->{$row->[0]} = {
                                                      id       => $row->[0],
                                                      id_frag  => $row->[3],
                                                      fn       => pdb_fn($frags->{$row->[3]}->{idcode}, $row->[1], $row->[2]),
                                                     };
}

$query = <<END;
SELECT g1.id,
       f_to_g2.id_frag,
       s.id
FROM   SeqGroup       AS g1,
       SeqToGroup     AS s_to_g1,
       Seq            AS s,
       SeqToGroup     AS s_to_g2,
       SeqGroup       AS g2,
       FragToSeqGroup AS f_to_g2
WHERE  g1.type = '$type'
AND    s_to_g1.id_group = g1.id
AND    s.id = s_to_g1.id_seq
AND    s.source = 'fist'
AND    s_to_g2.id_seq = s.id
AND    g2.id = s_to_g2.id_group
AND    g2.type = 'frag'
AND    f_to_g2.id_group = g2.id
END
$sth = $dbh->prepare($query);
$sth->execute;
$groups = {};
while($row = $sth->fetchrow_arrayref) {
    ($id_group, $id_frag, $id_seq) = @{$row};
    if(!defined($groups->{$id_group}->{$id_frag})) {
        $groups->{$id_group}->{$id_frag} = $id_seq;
    }
    else {
        warn "Error: already have a sequence for group $id_group frag $id_frag.";
        next;
    }
}

foreach $id_group (sort {$a <=> $b} keys %{$groups}) {
    print "%% group id = $id_group, type = '$type'\n";
    foreach $id_frag (sort {$a <=> $b} keys %{$groups->{$id_group}}) {
        $frag = $frags->{$id_frag};
        $id_seq = $groups->{$id_group}->{$id_frag};
        foreach $frag_inst (sort {$a->{id} <=> $b->{id}} values %{$frag->{frag_insts}}) {
            printf(
                   "%s %s-%d-%d-%d { %s }\n",
                   $frag_inst->{fn},
                   $frag->{idcode},
                   $id_frag,
                   $frag_inst->{id},
                   $id_seq,
                   $frag->{dom},
                  );
        }
    }
}

sub pdb_fn {
    my($idcode, $assembly, $model) = @_;

    my $fn;

    $fn = 'UNK';

    if($ENV{'DS'}) {
        if($assembly == 0) {
            $fn = sprintf "%s/pdb/%s/pdb%s.ent.gz", $ENV{DS}, substr($idcode, 1, 2), $idcode;
        }
        else {
            $fn = sprintf "%s/pdb-biounit/%s/%s-%s-%s.pdb.gz", $ENV{DS}, substr($idcode, 1, 2), $idcode, $assembly, $model;
        }
    }

    return $fn;
}
