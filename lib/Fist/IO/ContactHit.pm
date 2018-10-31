package Fist::IO::ContactHit;

use Moose;
use Carp ();
use namespace::autoclean;

=head1 NAME

 Fist::IO::ContactHit

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
    my $id_old;
    my $type;
    my $id_seq_a1;
    my $id_start_a1;
    my $id_end_a1;
    my $id_seq_b1;
    my $id_start_b1;
    my $id_end_b1;
    my $id_seq_a2;
    my $id_start_a2;
    my $id_end_a2;
    my $id_seq_b2;
    my $id_start_b2;
    my $id_end_b2;
    my $id_contact;
    my $n_res_a1;
    my $n_res_b1;
    my $n_resres_a1b1;
    my $pcid_a;
    my $e_value_a;
    my $pcid_b;
    my $e_value_b;
    my $chr;
    my $id_new;

    $fh = $self->fh;
    $i = 0;
    while(<$fh>) {
        ++$i;
        chomp;
        (
         $id_old,
         $type,
         $id_seq_a1,
         $id_start_a1,
         $id_end_a1,
         $id_seq_b1,
         $id_start_b1,
         $id_end_b1,
         $id_seq_a2,
         $id_start_a2,
         $id_end_a2,
         $id_seq_b2,
         $id_start_b2,
         $id_end_b2,
         $id_contact,
         $n_res_a1,
         $n_res_b1,
         $n_resres_a1b1,
         $pcid_a,
         $e_value_a,
         $pcid_b,
         $e_value_b,
         $chr,
        ) = split /\t/;

        if(!defined($type)) {
            Carp::cluck(join('', $self->fn, ':', $i, ' wrong number of columns'));
            next;
        }

        $id_new = $id_mapping->id_new($id_to_space->{id}, 'ContactHit', $id_old);
        print(
              $fh_out
              join(
                   "\t",
                   $id_new,
                   $type,
                   $id_seq_a1,
                   $id_start_a1,
                   $id_end_a1,
                   $id_seq_b1,
                   $id_start_b1,
                   $id_end_b1,
                   $id_seq_a2,
                   $id_start_a2,
                   $id_end_a2,
                   $id_seq_b2,
                   $id_start_b2,
                   $id_end_b2,
                   $id_contact,
                   $n_res_a1,
                   $n_res_b1,
                   $n_resres_a1b1,
                   $pcid_a,
                   $e_value_a,
                   $pcid_b,
                   $e_value_b,
                   $chr,
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
    return 'ContactHit';
}

=head2 column_names

 usage   :
 function: used internally to provide the column names in order used by tsv files
 args    : none
 returns : a list of column names

=cut

sub column_names {
    return(qw/id type id_seq_a1 start_a1 end_a1 id_seq_b1 start_b1 end_b1 id_seq_a2 start_a2 end_a2 id_seq_b2 start_b2 end_b2 id_contact n_res_a1 n_res_b1 n_resres_a1b1 pcid_a e_value_a pcid_b e_value_b @chr/);
}

=head2 set

 usage   :
 function: extra 'set' info for LOAD DATA LOCAL INFILE, depends on '@name' type column names
 args    : none
 returns : 'set' statement

=cut

sub set {
    return('SET chr = COMPRESS(@chr)');
}

__PACKAGE__->meta->make_immutable;
1;
