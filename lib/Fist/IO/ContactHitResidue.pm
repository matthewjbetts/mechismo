package Fist::IO::ContactHitResidue;

use Moose;
use Carp ();
use namespace::autoclean;

=head1 NAME

 Fist::IO::ContactHitResidue

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
    my $pos_a1;
    my $pos_b1;
    my $pos_a2;
    my $pos_b2;
    my $id_contact_hit_new;

    $fh = $self->fh;
    $i = 0;
    while(<$fh>) {
        ++$i;
        chomp;
        (
         $id_contact_hit_old,
         $pos_a1,
         $pos_b1,
         $pos_a2,
         $pos_b2,
        ) = split /\t/;

        if(!defined($pos_b2)) {
            Carp::cluck(join('', $self->fn, ':', $i, ' wrong number of columns'));
            next;
        }

        $id_contact_hit_new = $id_mapping->id_new($id_to_space->{id_contact_hit}, 'ContactHit', $id_contact_hit_old);
        print(
              $fh_out
              join(
                   "\t",
                   $id_contact_hit_new,
                   $pos_a1,
                   $pos_b1,
                   $pos_a2,
                   $pos_b2,
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
    return 'ContactHitResidue';
}

=head2 column_names

 usage   :
 function: used internally to provide the column names in order used by tsv files
 args    : none
 returns : a list of column names

=cut

sub column_names {
    return(qw/id_contact_hit pos_a1 pos_b1 pos_a2 pos_b2/);
}

__PACKAGE__->meta->make_immutable;
1;
