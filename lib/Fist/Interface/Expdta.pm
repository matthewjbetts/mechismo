package Fist::Interface::Expdta;

use Moose::Role;

=head1 NAME

 Fist::Interface::Pdb

=cut

=head1 ACCESSORS

=cut

=head2 idcode

 usage   :
 function:
 args    :
 returns :

=cut

requires 'idcode';

=head2 expdta

 usage   : $self->expdta
 function:
 args    :
 returns :

=cut

requires 'expdta';

=head1 ROLES

=cut

=head1 METHODS

=cut

=head2 TO_JSON

 usage   :
 function:
 args    :
 returns :

=cut

sub TO_JSON {
    my($self) = @_;

    my $json;

    $json = {
             expdta => $self->expdta,
            };

    return $json;
}

=head2 output_tsv

=cut

sub output_tsv {
    my($self, $fh) = @_;

    print $fh join("\t", $self->idcode, $self->expdta), "\n";
}

1;
