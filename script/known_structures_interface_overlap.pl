#!/usr/bin/perl -w

use strict;
use warnings;
use Getopt::Long;
use Cwd qw(abs_path getcwd);
use File::Path qw(make_path);
use Dir::Self;
use Config::General;
use DBI;
use Sys::CPU;
use Fist::Schema;
use Fist::NonDB::FragInst;
use Fist::NonDB::Contact;
use Fist::NonDB::ContactGroup;

# options
my $help;
my $dn_out_default = './data/';
my $dn_out = $dn_out_default;

# other variables
my $conf;
my $config;
my $schema;
my $dbh;
my $sth_rca;
my $rs_fia1;
my $fia1;
my $fib1;
my $fib2;
my $fa1;
my $fb1;
my $fb2;
my @contacts;
my $i;
my $j;
my $c1;
my $c2;
my $rca1;
my $rcb1;
my $na1;
my $na2;
my $intersection;
my $union;
my $jaccard;

# parse command line
GetOptions(
	   'help' => \$help,
	  );

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
$sth_rca = $dbh->prepare("SELECT chain1, resSeq1, iCode1 FROM ResContact WHERE id_frag_inst1 = ? AND id_frag_inst2 = ? GROUP BY chain1, resSeq1, iCode1");

print(
      join(
           "\t",
           'id_fia1',
           'idcode',
           'assembly',
           'model_a1',
           'dom_a1',
           'type_a1',

           'id_contact1',
           'id_fib1',
           'model_b1',
           'dom_b1',
           'type_b1',

           'id_contact2',
           'id_fib2',
           'model_b2',
           'dom_b2',
           'type_b2',

           'n_rc_a1',
           'n_rc_a2',
           'intersection',
           'union',
           'jaccard',
          ),
      "\n",
     );

$rs_fia1 = $schema->resultset('FragInst');
while($fia1 = $rs_fia1->next) {
    @contacts = $fia1->contact_id_frag_inst1s;
    if(@contacts > 1) {
        $fa1 = $fia1->frag;
        for($i = 0; $i < @contacts; $i++) {
            $c1 = $contacts[$i];
            $fib1 = $c1->frag_inst2;
            $fb1 = $fib1->frag;
            $rca1 = get_rca($sth_rca, $c1);
            for($j = $i + 1; $j < @contacts; $j++) {
                $c2 = $contacts[$j];
                $fib2 = $c2->frag_inst2;
                $fb2 = $fib2->frag;
                $rcb1 = get_rca($sth_rca, $c2);
                ($na1, $na2, $intersection, $union, $jaccard) = rca_overlap($rca1, $rcb1);
                print(
                      join(
                           "\t",
                           $fia1->id,
                           $fa1->idcode,
                           $fia1->assembly,
                           $fia1->model,
                           $fa1->dom,
                           $fa1->chemical_type,

                           $c1->id,
                           $fib1->id,
                           $fib1->model,
                           $fb1->dom,
                           $fb1->chemical_type,

                           $c2->id,
                           $fib2->id,
                           $fib2->model,
                           $fb2->dom,
                           $fb2->chemical_type,

                           $na1,
                           $na2,
                           $intersection,
                           $union,
                           $jaccard,
                          ),
                      "\n",
                     );
            }
        }
    }
}

sub get_rca {
    my($sth_rca, $c) = @_;

    my $rca;
    my $table;
    my $row;
    my $res;

    $sth_rca->execute($c->id_frag_inst1, $c->id_frag_inst2);
    $table = $sth_rca->fetchall_arrayref;
    $rca = {};
    foreach $row (@{$table}) {
        $res = join(':', @{$row});
        $rca->{$res}++;
    }

    return $rca;
}

sub rca_overlap {
    my($rca1, $rca2) = @_;

    my $n1;
    my $n2;
    my $rca3;
    my $res;
    my $intersection;
    my $union;
    my $jaccard;

    $n1 = scalar keys %{$rca1};
    $n2 = scalar keys %{$rca2};

    if($n1 > $n2) {
        $rca3 = $rca1;
        $rca1 = $rca2;
        $rca2 = $rca3;
    }

    $intersection = 0;
    foreach $res (keys %{$rca1}) {
        defined($rca2->{$res}) and $intersection++;
    }
    $union = $n1 + $n2 - $intersection;
    $jaccard = $intersection / $union;

    return($n1, $n2, $intersection, $union, $jaccard);
}
