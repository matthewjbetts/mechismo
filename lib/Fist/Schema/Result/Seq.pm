use utf8;
package Fist::Schema::Result::Seq;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Fist::Schema::Result::Seq

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

=head1 TABLE: C<Seq>

=cut

__PACKAGE__->table("Seq");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 primary_id

  data_type: 'varchar'
  is_nullable: 1
  size: 20

=head2 name

  data_type: 'varchar'
  is_nullable: 1
  size: 20

=head2 seq

  data_type: 'text'
  is_nullable: 1

=head2 len

  data_type: 'smallint'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 chemical_type

  data_type: 'varchar'
  is_nullable: 0
  size: 10

=head2 source

  data_type: 'varchar'
  is_nullable: 0
  size: 20

=head2 description

  data_type: 'text'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "primary_id",
  { data_type => "varchar", is_nullable => 1, size => 20 },
  "name",
  { data_type => "varchar", is_nullable => 1, size => 20 },
  "seq",
  { data_type => "text", is_nullable => 1 },
  "len",
  { data_type => "smallint", extra => { unsigned => 1 }, is_nullable => 0 },
  "chemical_type", { data_type => "varchar", is_nullable => 1, size => 10 },
  "source",
  { data_type => "varchar", is_nullable => 0, size => 20 },
  "description",
  { data_type => "text", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 aliases

Type: has_many

Related object: L<Fist::Schema::Result::Alias>

=cut

__PACKAGE__->has_many(
  "aliases",
  "Fist::Schema::Result::Alias",
  { "foreign.id_seq" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 feature_insts

Type: has_many

Related object: L<Fist::Schema::Result::FeatureInst>

=cut

__PACKAGE__->has_many(
  "feature_insts",
  "Fist::Schema::Result::FeatureInst",
  { "foreign.id_seq" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 frag_hit_id_seq1s

Type: has_many

Related object: L<Fist::Schema::Result::FragHit>

=cut

__PACKAGE__->has_many(
  "frag_hit_id_seq1s",
  "Fist::Schema::Result::FragHit",
  { "foreign.id_seq1" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 frag_hit_id_seq2s

Type: has_many

Related object: L<Fist::Schema::Result::FragHit>

=cut

__PACKAGE__->has_many(
  "frag_hit_id_seq2s",
  "Fist::Schema::Result::FragHit",
  { "foreign.id_seq2" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 go_annotations

Type: has_many

Related object: L<Fist::Schema::Result::GoAnnotation>

=cut

__PACKAGE__->has_many(
  "go_annotations",
  "Fist::Schema::Result::GoAnnotation",
  { "foreign.id_seq" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 seq_to_groups

Type: has_many

Related object: L<Fist::Schema::Result::SeqToGroup>

=cut

__PACKAGE__->has_many(
  "seq_to_groups",
  "Fist::Schema::Result::SeqToGroup",
  { "foreign.id_seq" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 seq_to_taxons

Type: has_many

Related object: L<Fist::Schema::Result::SeqToTaxon>

=cut

__PACKAGE__->has_many(
  "seq_to_taxons",
  "Fist::Schema::Result::SeqToTaxon",
  { "foreign.id_seq" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 id_taxons

Type: many_to_many

Composing rels: L</seq_to_taxons> -> id_taxon

=cut

__PACKAGE__->many_to_many("id_taxons", "seq_to_taxons", "id_taxon");


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-08-05 15:08:48
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:xvqQ1v8lnI1+KWkgzhEgbA

# You can replace this text with custom code or comments, and it will be preserved on regeneration

__PACKAGE__->many_to_many('taxa', 'seq_to_taxons', 'id_taxon');
__PACKAGE__->many_to_many('groups', 'seq_to_groups', 'id_group');

sub get_new_feature_inst {
    my($self) = @_;

    Carp::cluck('not implemented');
}

=head2 frag_hits

=cut

sub frag_hits {
    my($self) = @_;

    return $self->frag_hit_id_seq1s;
}

=head2 contact_hits

Type: has_many

Related object: L<Fist::Schema::Result::ContactHit>

=cut

__PACKAGE__->has_many(
  "contact_hits",
  "Fist::Schema::Result::ContactHit",
  { "foreign.id_seq_a1" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 frag

=cut

sub frag {
    my($self) = @_;

    my $seq_to_group;
    my $group;
    my $frag;

    # Seq -> SeqToGroup -> SeqGroup (type = 'frag') -> FragToSeqGroup -> Frag
    if(defined($seq_to_group = $self->search_related('seq_to_groups', {'id_group.type' => 'frag'}, {join => 'id_group'})->first)) {
        $group = $seq_to_group->group;
        ($frag) = $group->frags;
    }

    return $frag;
}

=head1 ROLES

 with 'Fist::Interface::Seq';

=cut

with 'Fist::Interface::Seq';

__PACKAGE__->meta->make_immutable;
1;
