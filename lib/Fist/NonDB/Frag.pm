package Fist::NonDB::Frag;

use strict;
use warnings;
use Moose;

=head1 NAME

 Fist::NonDB::Frag

=cut

=head1 ACCESSORS

=cut

has 'id' => (is => 'rw', isa => 'Int');
has 'schema' => (is => 'ro', isa => 'Fist::Schema');
has 'pdb' => (is => 'ro', isa => 'Fist::Interface::Pdb', weak_ref => 1);
has 'id_seq' => (is => 'rw', isa => 'Int', default => 0);
has 'fullchain' => (is => 'rw', isa => 'Bool');
has 'description' => (is => 'rw', isa => 'Str');
has 'chemical_type' => (is => 'rw', isa => 'Str');
has 'dom' => (is => 'ro', isa => 'Str');
has 'frag_insts' => (is => 'rw', isa => 'ArrayRef[Fist::Interface::FragInst]', default => sub {return []}, auto_deref => 1);
has 'scops' => (is => 'rw', isa => 'ArrayRef[Fist::Interface::Scop]', default => sub {return []}, auto_deref => 1);
has 'seq_groups' => (is => 'rw', isa => 'ArrayRef[Fist::Interface::SeqGroup]', default => sub {return []}, auto_deref => 1);
has '_seq_groups_by_type' => (is => 'rw', isa => 'HashRef', default => sub {return {}});
has 'chain_segments' => (is => 'rw', isa => 'ArrayRef[Fist::Interface::ChainSegment]', default => sub {return []}, auto_deref => 1);
has 'res_mappings' => (is => 'rw', isa => 'ArrayRef[Fist::Interface::FragResMapping]', default => sub {return []}, auto_deref => 1);

=head1 METHODS

=cut

sub add_to_frag_insts {
    my($self, @frag_insts) = @_;

    (@frag_insts > 0) and push(@{$self->frag_insts}, @frag_insts);
}

sub add_to_scops {
    my($self, @scops) = @_;

    (@scops > 0) and push(@{$self->scops}, @scops);
}

sub add_to_seq_groups {
    my($self, @seq_groups) = @_;

    my $seq_group;

    if(@seq_groups > 0) {
        push(@{$self->seq_groups}, @seq_groups);
        foreach $seq_group (@seq_groups) {
            defined($self->_seq_groups_by_type->{$seq_group->type}) or ($self->_seq_groups_by_type->{$seq_group->type} = []);
            push @{$self->_seq_groups_by_type->{$seq_group->type}}, $seq_group;
        }
    }
}

sub seq_groups_by_type {
    my($self, $type) = @_;

    my @seq_groups;

    @seq_groups = defined($self->_seq_groups_by_type->{$type}) ? @{$self->_seq_groups_by_type->{$type}} : ();

    return @seq_groups;
}

sub add_to_chain_segments {
    my($self, @chain_segments) = @_;

    (@chain_segments > 0) and push(@{$self->chain_segments}, @chain_segments);
}

=head2 _seq_by_source

 usage   :
 function:
 args    :
 returns :

=cut

sub _seq_by_source {
    my($self, $source) = @_;

    my $seq_group;
    my $seq;

    ($seq_group) = $self->seq_groups_by_type('frag');
    if(defined($seq_group)) {
        ($seq) = $seq_group->seqs_by_source($source);
    }

    return $seq;
}

=head2 fist_seq

 usage   :
 function: not implemented
 args    :
 returns :

=cut

sub fist_seq {
    my($self) = @_;

    return $self->_seq_by_source('fist');
}

=head2 interprets_seq

 usage   :
 function: not implemented
 args    :
 returns :

=cut

sub interprets_seq {
    my($self) = @_;

    return $self->_seq_by_source('interprets');
}

=head2 aln

 usage   :
 function: not implemented
 args    :
 returns :

=cut

sub aln {
    my($self) = @_;

    Carp::cluck('not implemented');
}

=head2 add_to_res_mappings

 usage   :
 function: not implemented
 args    :
 returns :

=cut

sub add_to_res_mappings {
    my($self, @res_mappings) = @_;

    (@res_mappings > 0) and push(@{$self->res_mappings}, @res_mappings);
}

=head2 _get_mapping

 usage   :
 function:
 args    :
 returns :

=cut

sub _get_mapping {
    my($self) = @_;

    my $mapping;
    my $fist_to_pdb;
    my $pdb_to_fist;
    my $res_mapping;
    my $fist;
    my $chain;
    my $resseq;
    my $icode;
    my $res3;
    my $res1;

    $mapping = $self->cache->get($self->cache_key);
    $fist_to_pdb = $mapping->{fist_to_pdb};
    $pdb_to_fist = $mapping->{pdb_to_fist};

    if(defined($mapping) and defined($fist_to_pdb) and defined($pdb_to_fist)) {
    }
    else {
        $fist_to_pdb = {};
        $pdb_to_fist = {};
        foreach $res_mapping ($self->res_mappings) {
            $fist = $res_mapping->fist;
            $chain = $res_mapping->chain;
            $resseq = $res_mapping->resseq;
            $icode = $res_mapping->icode;
            $res3 = $res_mapping->res3;
            $res1 = $res_mapping->res1;
            $fist_to_pdb->{$fist} = [$chain, $resseq, $icode, $res3, $res1];
            $pdb_to_fist->{$chain}->{$resseq}->{$icode} = $fist;
        }

        $mapping = {fist_to_pdb => $fist_to_pdb, pdb_to_fist => $pdb_to_fist};
        $self->cache->set($self->cache_key, $mapping);
    }

    return($fist_to_pdb, $pdb_to_fist);
}

=head1 ROLES

 with 'Fist::Interface::Frag';

=cut

with 'Fist::Interface::Frag';

__PACKAGE__->meta->make_immutable;
1;
