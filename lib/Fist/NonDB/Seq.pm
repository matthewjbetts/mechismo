package Fist::NonDB::Seq;

use strict;
use warnings;

use Moose;
use Fist::NonDB::FeatureInst;

=head1 NAME

 Fist::NonDB::Seq

=cut

=head1 ACCESSORS

=cut

has 'id' => (is => 'rw', isa => 'Int');
has 'primary_id' => (is => 'rw', isa => 'Str', default => '');
has 'name' => (is => 'rw', isa => 'Str', default => '');
has 'seq' => (is => 'rw', isa => 'Str', trigger => \&_set_len);
has 'len' => (is => 'rw', isa => 'Int');
has 'chemical_type' => (is => 'rw', isa => 'Str');
has 'source' => (is => 'rw', isa => 'Str');
has 'description' => (is => 'rw', isa => 'Str');
has 'aliases' => (is => 'rw', isa => 'ArrayRef[Fist::Interface::Alias]', default => sub {return []}, auto_deref => 1);
has 'feature_insts' => (is => 'rw', isa => 'ArrayRef[Fist::Interface::FeatureInst]', default => sub {return []}, auto_deref => 1);
has 'taxa' => (is => 'rw', isa => 'ArrayRef[Fist::Interface::Taxon]', default => sub {return []}, auto_deref => 1);

sub _set_len {
    my($self) = @_;

    $self->len(length($self->seq));
}

=head2 frag

 usage   :
 function: not implemented
 args    :
 returns :

=cut

sub frag {
    my($self) = @_;

    Carp::cluck('not implemented');
}

=head1 ROLES

 with 'Fist::Interface::Seq';

=cut

with 'Fist::Interface::Seq';

=head1 METHODS

=cut

sub BUILD {
    my($self) = @_;

    $self->id;
}

=head2 _new_feature_inst

 usage   : $seq->add_new_feature_inst(
                                      feature       => $feature,
                                      start_seq     => $start_seq,
                                      end_seq       => $end_seq,
                                      start_feature => $start_feature,
                                      end_feature   => $end_feature,
                                      e_value       => $e_value,
                                      score         => $score,
                                     );

 function: creates a new Fist::NonDB::FeatureInst and adds it to the sequence
 args    :
 returns : a Fist::NonDB::FeatureInst object

=cut

sub get_new_feature_inst {
    my($self, %args) = @_;

    my $feature_inst;

    $feature_inst = Fist::NonDB::FeatureInst->new(
                                                  seq           => $self,
                                                  feature       => $args{feature},
                                                  start_seq     => $args{start_seq} ? $args{start_seq} : 0,
                                                  end_seq       => $args{end_seq} ? $args{end_seq} : 0,
                                                  start_feature => $args{start_feature} ? $args{start_feature} : 0,
                                                  end_feature   => $args{end_feature} ? $args{end_feature} : 0,
                                                  e_value       => $args{e_value} ? $args{e_value} : 99999,
                                                  score         => $args{score} ? $args{score} : 0,
                                                 );
    return $feature_inst;
}

sub add_to_aliases {
    my($self, @aliases) = @_;

    (@aliases > 0) and push(@{$self->aliases}, @aliases);
}

sub add_to_feature_insts {
    my($self, @feature_insts) = @_;

    (@feature_insts > 0) and push(@{$self->feature_insts}, @feature_insts);
}

sub add_to_taxa {
    my($self, @taxa) = @_;

    (@taxa > 0) and push(@{$self->taxa}, @taxa);
}

__PACKAGE__->meta->make_immutable;
1;
