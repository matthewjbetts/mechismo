#!/usr/bin/perl -w

use strict;
use Getopt::Long;
use Cwd qw(abs_path getcwd);
use File::Path qw(make_path);
use Dir::Self;
use Config::General;
use Carp;
use Fist::Schema;
use List::Util 'shuffle';

my $conf;
my $config;
my $schema;
my $dbh;
my $query;
my $sth;
my @F;
my $table;
my $row;
my $idsQueries;
my $idSeqA1;
my $idSeqB1;
my $idCode;
my $idsContacts;
my $idContact;
my $idsFragInsts;
my $idsFist;
my $idFist;
my $fn;
my $name;
my $idGroup;
my $typeContactGroup;
my $n;

$conf = Config::General->new(__DIR__ . "/../fist.conf");
%{$config} = $conf->getall;
$schema = Fist::Schema->connect($config->{"Model::FistDB"}->{connect_info}->{dsn}, $config->{"Model::FistDB"}->{connect_info}->{user}, $config->{"Model::FistDB"}->{connect_info}->{password});
$dbh = $schema->storage->dbh;

if(0) {
    # contacts for particular queries
    $name = shift @ARGV;

    $idsQueries = {};
    @{$idsQueries}{@ARGV} = (1) x @ARGV;

    $fn = "${name}.queries.txt";
    print "$fn\n";
    open(OUT, ">$fn") or die;
    print OUT join("\n", @ARGV), "\n";
    close(OUT);

    open(IN, "zcat ./data/contact_hits/9606/query_to_fist.tsv.gz |") or die;
    #$fn = "${name}.query_to_fist.tsv";
    #print "$fn\n";
    #open(OUT, ">$fn") or die;
    $idsFist = {};
    while(<IN>) {
        @F = split /\t/;
        if(defined($idsQueries->{$F[4]})) {
            $idsFist->{$F[5]}++;
            #print OUT $_;
        }
    }
    #close(OUT);
    close(IN);

    # want all contacts involving these frags, inc. pcis and pdis
    $query = "SELECT c.id FROM Frag AS f, FragInst AS fi, Contact AS c WHERE f.id_seq = ? AND fi.id_frag = f.id AND c.id_frag_inst1 = fi.id";
    $sth = $dbh->prepare($query);
    foreach $idFist (sort keys %{$idsFist}) {
        $sth->execute($idFist);
        $table = $sth->fetchall_arrayref;
        foreach $row (@{$table}) {
            $idsContacts->{$row->[0]}++;
        }
    }
}
elsif(0) {
    # contacts for particular idcodes

    $name = shift @ARGV;
    $query = "SELECT c.id FROM Frag AS f, FragInst AS fi, Contact AS c WHERE f.idcode = ? AND fi.id_frag = f.id AND c.id_frag_inst1 = fi.id";
    $sth = $dbh->prepare($query);
    foreach $idCode (@ARGV) {
        $sth->execute($idCode);
        $table = $sth->fetchall_arrayref;
        foreach $row (@{$table}) {
            $idsContacts->{$row->[0]}++;
        }
    }
}
elsif(1) {
    # particular contacts

    $name = shift @ARGV;
    foreach $idContact (@ARGV) {
        $idsContacts->{$idContact}++;
    }
}
elsif(0) {
    # a random set of n contacts

    $name = shift @ARGV;
    $n = shift @ARGV;
    $query = 'SELECT id FROM Contact;';
    $sth = $dbh->prepare($query);
    $sth->execute();
    $table = $sth->fetchall_arrayref;
    $table = [shuffle(@{$table})];
    foreach $row (@{$table}[0..($n - 1)]) {
        $idsContacts->{$row->[0]}++;
    }
}
elsif(0) {
    # contacts in a particular group
    $name = 'cg' . join('.cg', @ARGV);

    $query = 'SELECT id_contact FROM ContactToGroup WHERE id_group = ?';
    $sth = $dbh->prepare($query);
    foreach $idGroup (@ARGV) {
        $sth->execute($idGroup);
        $table = $sth->fetchall_arrayref;
        foreach $row (@{$table}) {
            $idsContacts->{$row->[0]}++;
        }
    }
}

if(1) {
    $typeContactGroup = '0.0-0.8-0.8';
    open(IN, "./data/contact_groups/${typeContactGroup}.only.ContactToGroup.tsv") or die;
    $fn = "${name}.${typeContactGroup}.only.ContactToGroup.tsv";
    print "$fn\n";
    open(OUT, ">$fn") or die;
    while(<IN>) {
        @F = split /\t/;
        defined($idsContacts->{$F[0]}) or next;

        print(OUT $_);
    }
    close(OUT);
    close(IN);
}

if(1) {
    open(IN, "zcat data/contacts_with_fist_numbers.tsv.gz |") or die;
    $fn = "${name}.contacts_with_fist_numbers.tsv";
    print "$fn\n";
    open(OUT, ">$fn") or die;
    $idsFragInsts = {};
    while(<IN>) {
        @F = split /\t/;
        defined($idsContacts->{$F[0]}) or next;

        print(OUT $_);
        $idsFragInsts->{$F[1]}++;
        $idsFragInsts->{$F[2]}++;
    }
    close(OUT);
    close(IN);
}

if(1) {
    open(IN, "zcat data/frag_inst_to_fist.tsv.gz |") or die;
    $fn = "${name}.frag_inst_to_fist.tsv";
    print "$fn\n";
    open(OUT, ">$fn") or die;
    $idsFist = {};
    while(<IN>) {
        @F = split /\t/;
        chomp(@F);
        defined($idsFragInsts->{$F[0]}) or next;

        print(OUT $_);
        $idsFist->{$F[1]}++;
    }
    close(OUT);
    close(IN);
}

if(1) {
    # want all contacts involving these frags, inc. pcis and pdis
    open(IN, "zcat ./data/contact_hits/9606/query_to_fist.tsv.gz |") or die;
    $fn = "${name}.query_to_fist.tsv";
    print "$fn\n";
    open(OUT, ">$fn") or die;
    $idsQueries = {};
    while(<IN>) {
        @F = split /\t/;
        if(defined($idsFist->{$F[5]})) {
            $idsQueries->{$F[4]}++;
            print OUT $_;
        }
    }
    close(OUT);
    close(IN);

    open(QUERIES, ">${name}.queries.txt") or die;
    print QUERIES join("\n", keys %{$idsQueries}), "\n";
    close(QUERIES);
}

if(1) {
    open(IN, "zcat data/fist_vs_fist_aseqs.tsv.gz |") or die;
    $fn = "${name}.fist_vs_fist_aseqs.tsv";
    print "$fn\n";
    open(OUT, ">$fn") or die;
    while(<IN>) {
        @F = split /\t/;
        (defined($idsFist->{$F[4]}) and defined($idsFist->{$F[5]})) or next;
        print(OUT $_);
    }
    close(OUT);
    close(IN);
}
