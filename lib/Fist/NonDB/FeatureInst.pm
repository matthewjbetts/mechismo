package Fist::NonDB::FeatureInst;

use strict;
use warnings;
use Moose;

=head1 NAME

 Fist::NonDB::FeatureInst

=cut

=head1 ACCESSORS

=cut

has 'id'            => (is => 'rw', isa => 'Int');
has 'seq'           => (is => 'ro', isa => 'Any');
has 'feature'       => (is => 'ro', isa => 'Any');
has 'ac'            => (is => 'ro', isa => 'Str', default => '');
has 'start_seq'     => (is => 'ro', isa => 'Int', default => 0);
has 'end_seq'       => (is => 'ro', isa => 'Int', default => 0);
has 'start_feature' => (is => 'ro', isa => 'Int', default => 0);
has 'end_feature'   => (is => 'ro', isa => 'Int', default => 0);
has 'wt'            => (is => 'ro', isa => 'Str', default => '');
has 'mt'            => (is => 'ro', isa => 'Str', default => '');
has 'e_value'       => (is => 'ro', isa => 'Num', default => 99999);
has 'score'         => (is => 'ro', isa => 'Num', default => 0);
has 'true_positive' => (is => 'ro', isa => 'Bool', default => 0);
has 'description'   => (is => 'ro', isa => 'Str', default => '');
has 'enzymes'       => (is => 'rw', isa => 'ArrayRef[Any]', default => sub {return []}, auto_deref => 1);
has 'pmids'         => (is => 'rw', isa => 'ArrayRef[Fist::Interface::Pmid]', default => sub {return []}, auto_deref => 1);

=head1 METHODS

=cut

sub BUILD {
    my($self) = @_;

    $self->id;
}

=head2 add_to_pmids

 usage   :
 function:
 args    :
 returns :

=cut

sub add_to_pmids {
    my($self, @pmids) = @_;

    push @{$self->pmids}, @pmids;
}

=head1 ROLES

 with 'Fist::Interface::FeatureInst';

=cut

with 'Fist::Interface::FeatureInst';

__PACKAGE__->meta->make_immutable;
1;
