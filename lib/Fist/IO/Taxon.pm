package Fist::IO::Taxon;

use Moose;
use Carp ();
use Fist::NonDB::Taxon;
use namespace::autoclean;

=head1 NAME

 Fist::IO::Taxon

=cut

=head1 ROLES

 with 'Fist::IO';

=cut

with 'Fist::IO';

=head1 METHODS

=cut

=head2 parse_ncbi_names

 usage   : $self->parse_ncbi_names();
 function: parse NCBI taxonomy 'names.dmp' file
 args    : none
 returns : a list of Fist::NonDB::Taxon objects, or undef on error

=cut

sub parse_ncbi_names {
    my($self, $parents) = @_;

    my %S;
    my $fh;
    my @F;
    my $id;
    my @taxa;
    my $taxon;

    $fh = $self->fh;

    %S = ();
    while(<$fh>) {
        @F = split /\s*\|\s*/;
        if($F[3] eq "scientific name") {
            $S{$F[0]}->{sci} = $F[1];
        }
        elsif($F[3] eq "genbank common name") {
            $S{$F[0]}->{com} = $F[1];
        }
    }

    @taxa = ();
    foreach $id (sort {$a <=> $b} keys %S) {
        $taxon = Fist::NonDB::Taxon->new(
                                         id              => $id,
                                         id_parent       => $parents->{$id},
                                         scientific_name => $S{$id}->{sci} ? $S{$id}->{sci} : '',
                                         common_name     => $S{$id}->{com} ? $S{$id}->{com} : '',
                                        );
        push @taxa, $taxon;
    }

    return @taxa;
}

=head2 resultset_name

 usage   :
 function: used internally to provide the result set name
 args    : none
 returns : the name of the result set

=cut

sub resultset_name {
    return 'Taxon';
}

=head2 column_names

 usage   :
 function: used internally to provide the column names in order used by tsv files
 args    : none
 returns : a list of column names

=cut

sub column_names {
    return(qw/id id_parent scientific_name common_name/);
}

__PACKAGE__->meta->make_immutable;
1;
