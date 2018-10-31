package Fist::IO::SeqToGroup;

use Moose;
use Carp ();
use Fist::Utils::IdMapping;
use namespace::autoclean;

=head1 NAME

 Fist::IO::SeqToGroup

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
    my $id_seq_old;
    my $id_group_old;
    my $id_seq_new;
    my $id_group_new;
    my $rep;

    $fh = $self->fh;
    while(<$fh>) {
        ($id_seq_old, $id_group_old, $rep) = split;

        if(!defined($id_seq_new = $id_mapping->id_new($id_to_space->{id_seq}, 'Seq', $id_seq_old))) {
            Carp::confess("no new id for seq $id_seq_old");
            return 0;
        }
        #print join("\t", __PACKAGE__, 'id_seq', $id_seq_old, $id_seq_new), "\n";

        if(!defined($id_group_new = $id_mapping->id_new($id_to_space->{id_group}, 'SeqGroup', $id_group_old))) {
            Carp::confess("no new id for group $id_group_old");
            return 0;
        }
        #print join("\t", __PACKAGE__, 'id_group', $id_group_old, $id_group_new), "\n";

        print $fh_out join("\t", $id_seq_new, $id_group_new, $rep), "\n";
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
    return 'SeqToGroup';
}

=head2 column_names

 usage   :
 function: used internally to provide the column names in order used by tsv files
 args    : none
 returns : a list of column names

=cut

sub column_names {
    return(qw/id_seq id_group rep/);
}

__PACKAGE__->meta->make_immutable;
1;
