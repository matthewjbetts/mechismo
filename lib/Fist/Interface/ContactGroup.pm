package Fist::Interface::ContactGroup;

use Moose::Role;

=head1 NAME

 Fist::Interface::ContactGroup

=cut

=head1 ACCESSORS

=cut

=head2 id

 usage   :
 function:
 args    :
 returns :

=cut

requires 'id';

=head2 id_parent

 usage   :
 function:
 args    :
 returns :

=cut

requires 'id_parent';

=head2 type

 usage   :
 function:
 args    :
 returns :

=cut

requires 'type';

=head1 ROLES

 with 'Fist::Utils::UniqueIdentifier';

=cut

with 'Fist::Utils::UniqueIdentifier';

=head1 METHODS

=cut

requires 'add_to_contacts';

sub output_tsv {
    my($self, $fh) = @_;

    print $fh join("\t", $self->id, $self->id_parent, $self->type), "\n";
}

1;
