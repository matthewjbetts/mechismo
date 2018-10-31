package Fist::Utils::Hmmscan;

use Moose::Role;
use Carp ();
use File::Temp ();
use Fist::NonDB::FeatureInst;
use namespace::autoclean;

=head1 NAME

 Fist::Utils::Hmmscan - a Moose::Role

=cut

=head1 ACCESSORS

=cut

=head2 seqs

 usage   : $self->seqs
 function: method required of classes that consume this role
 args    : none
 returns : a list of Fist::Interface::Seq objects

=cut

requires 'seqs';

=head1 ROLES

 with 'Fist::Utils::System';

=cut

with 'Fist::Utils::System';

=head1 METHODS

=cut

=head2 run_hmmscan

 usage   : $self->run_hmmscan(
                              -schema => $schema,
                              -source => 'Pfam',       # feature source
                              -db     => 'Pfam-A.hmm', # database [required]
                              -e      => 1e-6,         # E-value, default = use pfam gathering threshold
                             );
 function: runs hmmscan
 args    : schema, feature source, e_value threshold, file name of HMM database
 returns : undef on error

=cut

sub run_hmmscan {
    my($self, %args) = @_;

    my $seqs_hash;
    my $e;
    my $schema;
    my $source;
    my $db;
    my $e_default = 0.01;
    my $tmpfile_seq;
    my $tmpfile_hmmscan;
    my $cmd;
    my $stat;
    my $seq;
    my $fh;
    my @feat_insts;
    my $feat_inst;

    my $name_feat;
    my $ac_feat;
    my $tlen;

    my $id_query;
    my $ac_query;
    my $qlen;

    my $e_value_full;
    my $score_full;
    my $bias_full;

    my $n_dom;
    my $t_dom;
    my $c_e_value_dom;
    my $i_e_value_dom;
    my $score_dom;
    my $bias_dom;

    my $start_hmm;
    my $end_hmm;
    my $start_ali;
    my $end_ali;
    my $start_env; # hmmer-speak for start of the envelope of the match on the target sequence
    my $end_env;
    my $accuracy;
    my $description_target;

    my $feature;

    if(!defined($db = $args{db})) {
        Carp::cluck('no hmm database specified');
        return undef;
    }

    if(!defined($source = $args{source})) {
        Carp::cluck('no feature source specified');
        return undef;
    }

    if(!defined($schema = $args{schema})) {
        Carp::cluck('no schema given');
        return undef;
    }

    $e = $args{e};

    $tmpfile_seq = File::Temp->new(DIR => $self->tempdir, UNLINK => $self->cleanup);
    $seqs_hash = {};
    foreach $seq ($self->seqs) {
        $seq->output_fasta($tmpfile_seq);
        $seqs_hash->{$seq->id} = $seq;
    }

    $tmpfile_hmmscan = File::Temp->new(DIR => $self->tempdir, UNLINK => $self->cleanup);
    $cmd = defined($e) ? "hmmscan --domE $e --domtblout $tmpfile_hmmscan $db $tmpfile_seq &> /dev/null" : "hmmscan --cut_ga --domtblout $tmpfile_hmmscan $db $tmpfile_seq &> /dev/null";
    $stat = $self->mysystem($cmd);
    $stat >>= 8;
    if($stat != 0) {
        Carp::cluck("'$cmd' failed with status $stat: '$!'");
        return undef;
    }

    if(!open($fh, $tmpfile_hmmscan)) {
        Carp::cluck("cannot open '$tmpfile_hmmscan' for reading.");
        return undef;
    }

    @feat_insts = ();
    while(<$fh>) {
        # #                                                                            --- full sequence --- -------------- this domain -------------   hmm coord   ali coord   env coord
        # # target name        accession   tlen query name           accession   qlen   E-value  score  bias   #  of  c-Evalue  i-Evalue  score  bias  from    to  from    to  from    to  acc description of target
        # #------------------- ---------- ----- -------------------- ---------- ----- --------- ------ ----- --- --- --------- --------- ------ ----- ----- ----- ----- ----- ----- ----- ---- ---------------------
        # Acetate_kinase       PF00871.12   388 5778                 -            390  7.6e-170  564.5   1.5   1   1  5.8e-174  8.6e-170  564.4   1.1     1   388     5   382     5   382 0.99 Acetokinase family
        # PP-binding           PF00550.20    67 6267                 -             84   6.5e-14   51.9   0.7   1   1   5.1e-18   7.6e-14   51.7   0.5     2    67     9    75     8    75 0.94 Phosphopantetheine attachment site
        # ADH_zinc_N           PF00107.21   130 9901                 -            351   2.2e-19   69.2   0.4   1   1   4.6e-23   3.4e-19   68.6   0.3     1   117   177   297   177   311 0.85 Zinc-binding dehydrogenase

        /^#/ and next;
        (
         $name_feat,
         $ac_feat,
         $tlen,

         $id_query,
         $ac_query,
         $qlen,

         $e_value_full,
         $score_full,
         $bias_full,

         $n_dom,
         $t_dom,
         $c_e_value_dom, # conditional e-value
         $i_e_value_dom, # independent e-value
         $score_dom,
         $bias_dom,

         $start_hmm,
         $end_hmm,
         $start_ali,
         $end_ali,
         $start_env, # hmmer-speak for start of the envelope of the match on the target sequence
         $end_env,
         $accuracy,
         $description_target,
        ) = split /\s+/, $_, 23;

        $ac_feat =~ s/\.\d+\Z//;
        if(!defined($feature = $schema->resultset('Feature')->search({source => $source, ac_src => $ac_feat})->first)) {
            Carp::cluck("Feature source='$source' ac_src='$ac_feat' not found");
            next;
        }

        if(!defined($seq = $seqs_hash->{$id_query})) {
            Carp::cluck("Seq id='$id_query' not found");
            next;
        }

        $feat_inst = Fist::NonDB::FeatureInst->new(
                                                   seq           => $seq,
                                                   feature       => $feature,
                                                   start_seq     => $start_env,
                                                   end_seq       => $end_env,
                                                   start_feature => $start_hmm,
                                                   end_feature   => $end_hmm,
                                                   e_value       => $i_e_value_dom,
                                                   score         => $score_dom,
                                                  );
        push @feat_insts, $feat_inst;
    }
    close($fh);

    return(@feat_insts);
}

1;
