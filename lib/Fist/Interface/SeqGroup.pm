package Fist::Interface::SeqGroup;

use Moose::Role;

=head1 NAME

 Fist::Interface::SeqGroup

=cut

=head1 ACCESSORS

=cut

=head2 id

 usage   :
 function:
 args    :
 returns :

=cut

requires 'id';

=head2 type

 usage   :
 function:
 args    :
 returns :

=cut

requires 'type';

=head2 ac

 usage   :
 function:
 args    :
 returns :

=cut

requires 'ac';

=head2 alignments

 usage   :
 function:
 args    :
 returns :

=cut

requires 'alignments';

=head1 ROLES

 with 'Fist::Interface::Seqs';
 with 'Fist::Utils::UniqueIdentifier';

=cut

with 'Fist::Interface::Seqs';
with 'Fist::Utils::UniqueIdentifier';

=head1 METHODS

=cut

requires 'add_to_seqs';
requires 'add_to_alignments';
requires 'seqs_by_source';

sub output_tsv {
    my($self, $fh) = @_;

    print $fh join("\t", $self->id, $self->type, $self->ac ? $self->ac : ''), "\n";
}

1;
