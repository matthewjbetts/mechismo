use strict;
use warnings;
use Test::More;

use Fist::IO::Pdb;
use Fist::NonDB::Pdb;
use Fist::NonDB::Frag;
use Fist::NonDB::FragInst;

my $cleanup = 1;
my $tempdir;
my $pdbio;
my $pdb;
my $frag;
my @frag_insts;
my $frag_inst;
my $cofm;
my $fn_contacts;
my $fh_contacts;
my $fn_res_contacts;
my $fh_res_contacts;
my $i;
my $j;
my $label;
my $fn_contacts_ref;
my $fn_res_contacts_ref;
my $ok_contacts;
my $ok_res_contacts;

eval { $pdb = Fist::NonDB::Pdb->new(idcode => '4HHB'); };
ok(!$@, 'constructed pdb object from idCode');
#print $pdb->id, "\n";

eval { $frag = Fist::NonDB::Frag->new(pdb => $pdb, dom => 'ALL'); };
ok(!$@, 'constructed frag object from pdb object');
$pdb->add_to_frags($frag);

eval { $frag_inst = Fist::NonDB::FragInst->new(frag => $frag, assembly => 0, model => 0); };
ok(!$@, 'constructed fraginst object');
$frag->add_to_frag_insts($frag_inst);

# read pdb
eval { $pdbio = Fist::IO::Pdb->new(fn => 't/files/pdb4hhb.ent.gz'); };
ok(!$@, 'pdbio set up');

$tempdir = File::Temp->newdir(CLEANUP => $cleanup);

$pdb = $pdbio->parse($tempdir, $cleanup);
ok($pdb, 'pdb file parsed');

# get frag insts
@frag_insts = ();
foreach $frag ($pdb->frags) {
    eval {$frag_inst = Fist::NonDB::FragInst->new(frag => $frag, assembly => 0, model => 0); };
    ok(!$@, join(' ', 'frag', $frag->id, '- constructed fraginst object'));
    $frag_inst->tempdir($tempdir);
    $frag_inst->cleanup($cleanup);
    $frag->add_to_frag_insts($frag_inst);
    push @frag_insts, $frag_inst;
}

done_testing();
