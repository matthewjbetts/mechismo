package Fist::Interface::Alias;

use Moose::Role;

=head1 NAME

 Fist::Interface::Alias

=cut

=head1 ACCESSORS

=cut

=head2 seq

 usage   :
 function:
 args    :
 returns :

=cut

requires 'seq';

=head2 alias

 usage   :
 function:
 args    :
 returns :

=cut

requires 'alias';

=head2 type

 usage   :
 function:
 args    :
 returns :

=cut

requires 'type';

=head1 ROLES

=cut

=head1 METHODS

=cut

sub output_tsv {
    my($self, $fh) = @_;

    print $fh join("\t", $self->seq->id, $self->alias, $self->type), "\n";
}

1;
