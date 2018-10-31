use utf8;
package Fist::Schema::Result::SeqGroup;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Fist::Schema::Result::SeqGroup

=cut

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';

=head1 COMPONENTS LOADED

=over 4

=item * L<DBIx::Class::InflateColumn::DateTime>

=back

=cut

__PACKAGE__->load_components("InflateColumn::DateTime");

=head1 TABLE: C<SeqGroup>

=cut

__PACKAGE__->table("SeqGroup");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 type

  data_type: 'varchar'
  is_nullable: 0
  size: 50

=head2 ac

  data_type: 'varchar'
  is_nullable: 0
  size: 30

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "type",
  { data_type => "varchar", is_nullable => 0, size => 50 },
  "ac",
  { data_type => "varchar", is_nullable => 0, size => 30 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 alignment_to_groups

Type: has_many

Related object: L<Fist::Schema::Result::AlignmentToGroup>

=cut

__PACKAGE__->has_many(
  "alignment_to_groups",
  "Fist::Schema::Result::AlignmentToGroup",
  { "foreign.id_group" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 frag_to_seq_groups

Type: has_many

Related object: L<Fist::Schema::Result::FragToSeqGroup>

=cut

__PACKAGE__->has_many(
  "frag_to_seq_groups",
  "Fist::Schema::Result::FragToSeqGroup",
  { "foreign.id_group" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 seq_to_groups

Type: has_many

Related object: L<Fist::Schema::Result::SeqToGroup>

=cut

__PACKAGE__->has_many(
  "seq_to_groups",
  "Fist::Schema::Result::SeqToGroup",
  { "foreign.id_group" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 id_alns

Type: many_to_many

Composing rels: L</alignment_to_groups> -> id_aln

=cut

__PACKAGE__->many_to_many("id_alns", "alignment_to_groups", "id_aln");

=head2 id_frags

Type: many_to_many

Composing rels: L</frag_to_seq_groups> -> id_frag

=cut

__PACKAGE__->many_to_many("id_frags", "frag_to_seq_groups", "id_frag");


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2012-12-20 13:44:35
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:eIqoJaIblP+6LlOOymNANA


# You can replace this text with custom code or comments, and it will be preserved on regeneration

__PACKAGE__->many_to_many('seqs', 'seq_to_groups', 'id_seq');
__PACKAGE__->many_to_many('alignments', 'alignment_to_groups', 'id_aln');
__PACKAGE__->many_to_many("frags", "frag_to_seq_groups", "id_frag");

=head2 seqs_by_source

 usage   :
 function:
 args    :
 returns :

=cut

sub seqs_by_source {
    my($self, $source) = @_;

    my @seqs;
    my $seq_to_group;

    @seqs = ();
    foreach $seq_to_group ($self->search_related('seq_to_groups')) {
        ($seq_to_group->seq->source eq $source) and push(@seqs, $seq_to_group->seq);
    }

    return @seqs;
}

=head1 ROLES

 with 'Fist::Interface::SeqGroup';

=cut

with 'Fist::Interface::SeqGroup';

__PACKAGE__->meta->make_immutable;
1;
