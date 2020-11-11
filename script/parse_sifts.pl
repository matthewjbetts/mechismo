#!/usr/bin/perl -w

use strict;
use warnings;
use Getopt::Long;
use Fist::Schema;
use Dir::Self;
use Config::General;
use Carp;

# options
my $help;

# other variables
my $conf;
my $config;
my $schema;
my $idcode;
my $chain;
my $ac;
my $dom;
my $rs_frag;
my $rs_seq;
my $frag;
my @seq_groups;
my $seq_group;
my @seqs;
my $seq;
my $n;

# parse command line
GetOptions(
	   'help' => \$help,
	  );

defined($help) and usage();
(@ARGV == 0) and usage();

sub usage {
    my($msg) = @_;

    my $prog;
    my $usage;

    ($prog = __FILE__) =~ s/.*\///;

    defined($msg) and warn("\nUsage problem: $msg\n");

    $usage = <<END;

Usage: $prog [options] < sifts/pdb_chain_uniprot.lst

option  parameter  description                     default
------  ---------  ------------------------------  -------
--help  [none]     print this usage info and exit

END
}

$conf = Config::General->new(__DIR__ . "/../fist.conf");
%{$config} = $conf->getall;
$schema = Fist::Schema->connect($config->{"Model::FistDB"}->{connect_info}->{dsn}, $config->{"Model::FistDB"}->{connect_info}->{user}, $config->{"Model::FistDB"}->{connect_info}->{password});
$rs_frag = $schema->resultset('Frag');
$rs_seq = $schema->resultset('Seq');
while(<STDIN>) {
    /^#/ and next;
    /^PDB/ and next;
    ($idcode, $chain, $ac) = split;

    # get the frags with this idcode and chain
    $n = 0;
    foreach $frag ($rs_frag->search({idcode => $idcode})->all()) {
        if(($frag->dom eq "CHAIN $chain") or ($frag->dom =~ /$chain -{0,1}\d+/)) {
            $n++;
            @seq_groups = ();
            foreach $seq_group ($frag->seq_groups) {
                ($seq_group->type eq 'frag') and push(@seq_groups, $seq_group);
            }

            # get the sequence with the given uniprot accession
            @seqs = $rs_seq->search(
                                    {
                                     'aliases.alias' => $ac,
                                     'aliases.type'  => 'UniProtKB accession',
                                    },
                                    {
                                     join => 'aliases',
                                    },
                                   );

            # add the sequence to the sequence groups
            foreach $seq_group (@seq_groups) {
                foreach $seq (@seqs) {
                    print join("\t", $seq->id, $seq_group->id, 0), "\n"; # FIXME - use object method
                }
            }
        }
    }
    ($n == 0) and Carp::cluck("Warning: no fragment with idcode='$idcode' and chain='$chain'.");
}
