package Fist::IO::Pmid;

use Moose;
use Carp ();
use namespace::autoclean;

=head1 NAME

 Fist::IO::Pmid

=cut

=head1 ROLES

 with 'Fist::IO';

=cut

with 'Fist::IO';

=head1 METHODS

=cut

=head2 resultset_name

 usage   :
 function: used internally to provide the result set name
 args    : none
 returns : the name of the result set

=cut

sub resultset_name {
    return 'Pmid';
}

=head2 column_names

 usage   :
 function: used internally to provide the column names in order used by tsv files
 args    : none
 returns : a list of column names

=cut

sub column_names {
    return(qw/pmid throughput/);
}

__PACKAGE__->meta->make_immutable;
1;
