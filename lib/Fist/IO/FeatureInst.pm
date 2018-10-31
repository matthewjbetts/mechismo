package Fist::IO::FeatureInst;

use Moose;
use Carp ();
use Fist::Utils::IdMapping;
use namespace::autoclean;

=head1 NAME

 Fist::IO::FeatureInst

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
    my $id_old;
    my $id_new;
    my $id_seq_old;
    my $id_seq_new;
    my $id_feature_old;
    my $id_feature_new;
    my $ac;
    my $start_seq;
    my $end_seq;
    my $start_feature;
    my $end_feature;
    my $wt;
    my $mt;
    my $e_value;
    my $score;
    my $tp;
    my $description;

    $fh = $self->fh;
    while(<$fh>) {
        chomp;
        ($id_old, $id_seq_old, $id_feature_old, $ac, $start_seq, $end_seq, $start_feature, $end_feature, $wt, $mt, $e_value, $score, $tp, $description) = split /\t/;

        $id_new = $id_mapping->id_new($id_to_space->{id}, 'FeatureInst', $id_old);
        $id_seq_new = $id_mapping->id_new($id_to_space->{id_seq}, 'Seq', $id_seq_old);
        $id_feature_new = $id_mapping->id_new($id_to_space->{id_feature}, 'Feature', $id_feature_old);

        print $fh_out join("\t", $id_new, $id_seq_new, $id_feature_new, $ac, $start_seq, $end_seq, $start_feature, $end_feature, $wt, $mt, $e_value, $score, $tp, $description), "\n";
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
    return 'FeatureInst';
}

=head2 column_names

 usage   :
 function: used internally to provide the column names in order used by tsv files
 args    : none
 returns : a list of column names

=cut

sub column_names {
    return(qw/id id_seq id_feature ac start_seq end_seq start_feature end_feature wt mt e_value score true_positive description/);
}

__PACKAGE__->meta->make_immutable;
1;
