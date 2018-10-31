package Fist::IO::ContactHitInterprets;

use Moose;
use Carp ();
use namespace::autoclean;

=head1 NAME

 Fist::IO::ContactHitInterprets

=cut

=head1 ROLES

 with 'Fist::IO';

=cut

with 'Fist::IO';

=head1 METHODS

=cut

=head2 tsv_id_map

 usage   : $self->tsv_id_map($id_mapping, $id_to_space, \*STDOUT);
 function: parse tsv file, assign new unique identifiers,
           store mapping of new to old in id mapping hash.
 args    : Fist::Utils::IdMapping object, string, file handle GLOB
 returns : 1 on success, 0 on failure

=cut

sub tsv_id_map {
    my($self, $id_mapping, $id_to_space, $fh_out) = @_;

    my $fh;
    my $i;
    my $id_contact_hit_old;
    my $mode;
    my $rand;
    my $raw;
    my $mean;
    my $sd;
    my $z;
    my $id_contact_hit_new;

    $fh = $self->fh;
    $i = 0;
    while(<$fh>) {
        ++$i;
        chomp;
        (
         $id_contact_hit_old,
         $mode,
         $rand,
         $raw,
         $mean,
         $sd,
         $z,
        ) = split /\t/;

        if(!defined($z) or ($z eq '')) {
            Carp::cluck(join('', $self->fn, ':', $i, ' wrong number of columns'));
            next;
        }

        $id_contact_hit_new = $id_mapping->id_new($id_to_space->{id_contact_hit}, 'ContactHit', $id_contact_hit_old);
        print(
              $fh_out
              join(
                   "\t",
                   $id_contact_hit_new,
                   $mode,
                   $rand,
                   $raw,
                   $mean,
                   $sd,
                   $z,
                  ),
              "\n",
             );
    }

    return 1;
}

=head2 resultset_name

 usage   :
 function: used internally to provide the result set name
 args    : none
 returns : the name of the result set

=cut

sub resultset_name {
    return 'ContactHitInterprets';
}

=head2 column_names

 usage   :
 function: used internally to provide the column names in order used by tsv files
 args    : none
 returns : a list of column names

=cut

sub column_names {
    return(qw/id_contact_hit mode rand raw mean sd z/);
}

__PACKAGE__->meta->make_immutable;
1;
