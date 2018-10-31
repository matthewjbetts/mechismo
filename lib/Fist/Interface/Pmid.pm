package Fist::Interface::Pmid;

use Moose::Role;

=head1 NAME

 Fist::Interface::Pmid

=cut

=head1 ACCESSORS

=cut

=head2 pmid

 usage   :
 function:
 args    :
 returns :

=cut

requires 'pmid';

=head2 throughput

 usage   :
 function:
 args    :
 returns :

=cut

requires 'throughput';

=head1 ROLES

=cut

=head1 METHODS

=cut

=head2 output_tsv

 usage   :
 function:
 args    :
 returns :

=cut

sub output_tsv {
    my($self, $fh) = @_;

    print $fh join("\t", $self->pmid, $self->throughput), "\n";
}

1;
