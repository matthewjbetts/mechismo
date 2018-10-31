package Fist::NonDB::ContactHit;

use strict;
use warnings;
use Moose;

=head1 NAME

 Fist::NonDB::ContactHit

=cut

=head1 ACCESSORS

=cut

has 'id'            => (is => 'rw', isa => 'Int');
has 'type'          => (is => 'ro', isa => 'Str');
has 'seq_a1'        => (is => 'ro', isa => 'Any');
has 'start_a1'      => (is => 'ro', isa => 'Any');
has 'end_a1'        => (is => 'ro', isa => 'Any');
has 'seq_b1'        => (is => 'ro', isa => 'Any');
has 'start_b1'      => (is => 'ro', isa => 'Any');
has 'end_b1'        => (is => 'ro', isa => 'Any');
has 'seq_a2'        => (is => 'ro', isa => 'Any');
has 'start_a2'      => (is => 'ro', isa => 'Any');
has 'end_a2'        => (is => 'ro', isa => 'Any');
has 'seq_b2'        => (is => 'ro', isa => 'Any');
has 'start_b2'      => (is => 'ro', isa => 'Any');
has 'end_b2'        => (is => 'ro', isa => 'Any');
has 'contact'       => (is => 'ro', isa => 'Any');
has 'n_res_a1'      => (is => 'ro', isa => 'Int', default => 0);
has 'n_res_b1'      => (is => 'ro', isa => 'Int', default => 0);
has 'n_resres_a1b1' => (is => 'ro', isa => 'Int', default => 0);
has 'pcid_a'        => (is => 'ro', isa => 'Num', default => 0);
has 'e_value_a'     => (is => 'ro', isa => 'Num', default => 0);
has 'pcid_b'        => (is => 'ro', isa => 'Num', default => 0);
has 'e_value_b'     => (is => 'ro', isa => 'Num', default => 0);
has 'hsp_a'         => (is => 'rw', isa => 'Any');
has 'hsp_b'         => (is => 'rw', isa => 'Any');
has 'hsp_query'     => (is => 'rw', isa => 'Any');
has 'hsp_template'  => (is => 'rw', isa => 'Any');
has 'contact_hit_interprets' => (is => 'rw', isa => 'ArrayRef[Any]', default => sub { return []});

=head1 METHODS

=cut

sub BUILD {
    my($self) = @_;

    $self->id;
}

sub id_seq_a1 {
    my($self) = @_;

    $self->seq_a1->id;
}

sub id_seq_b1 {
    my($self) = @_;

    $self->seq_b1->id;
}

sub id_seq_a2 {
    my($self) = @_;

    $self->seq_a2->id;
}

sub id_seq_b2 {
    my($self) = @_;

    $self->seq_b2->id;
}

=head2 add_to_contact_hit_interprets

 usage   :
 function:
 args    :
 returns :

=cut

sub add_to_contact_hit_interprets {
    my($self, @contact_hit_interprets) = @_;

    push @{$self->contact_hit_interprets}, @contact_hit_interprets;
}

=head1 ROLES

 with 'Fist::Interface::ContactHit';

=cut

with 'Fist::Interface::ContactHit';

__PACKAGE__->meta->make_immutable;
1;
