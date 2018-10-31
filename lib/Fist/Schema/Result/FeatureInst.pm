use utf8;
package Fist::Schema::Result::FeatureInst;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Fist::Schema::Result::FeatureInst

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

=head1 TABLE: C<FeatureInst>

=cut

__PACKAGE__->table("FeatureInst");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 id_seq

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 id_feature

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 ac

  data_type: 'varchar'
  is_nullable: 0
  size: 30

=head2 start_seq

  data_type: 'smallint'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 end_seq

  data_type: 'smallint'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 start_feature

  data_type: 'smallint'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 end_feature

  data_type: 'smallint'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 wt

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 mt

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 e_value

  data_type: 'double precision'
  is_nullable: 0

=head2 score

  data_type: 'float'
  is_nullable: 0

=head2 true_positive

  data_type: 'tinyint'
  default_value: 0
  is_nullable: 0

=cut

=head2 description

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "id_seq",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "id_feature",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "ac",
  { data_type => "varchar", default_value => '', is_nullable => 0, size => 30 },
  "start_seq",
  { data_type => "smallint", extra => { unsigned => 1 }, is_nullable => 0 },
  "end_seq",
  { data_type => "smallint", extra => { unsigned => 1 }, is_nullable => 0 },
  "start_feature",
  { data_type => "smallint", extra => { unsigned => 1 }, is_nullable => 0 },
  "end_feature",
  { data_type => "smallint", extra => { unsigned => 1 }, is_nullable => 0 },
  "wt",
  { data_type => "varchar", default_value => '', is_nullable => 0 },
  "mt",
  { data_type => "varchar", default_value => '', is_nullable => 0 },
  "e_value",
  { data_type => "double precision", is_nullable => 0 },
  "score",
  { data_type => "float", is_nullable => 0 },
  "true_positive",
  { data_type => "tinyint", default_value => 0, is_nullable => 0 },
  "description",
  { data_type => "text", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 feature_inst_contact_id_feat_inst1s

Type: has_many

Related object: L<Fist::Schema::Result::FeatureInstContact>

=cut

__PACKAGE__->has_many(
  "feature_inst_contact_id_feat_inst1s",
  "Fist::Schema::Result::FeatureInstContact",
  { "foreign.id_feat_inst1" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 feature_inst_contact_id_feat_inst2s

Type: has_many

Related object: L<Fist::Schema::Result::FeatureInstContact>

=cut

__PACKAGE__->has_many(
  "feature_inst_contact_id_feat_inst2s",
  "Fist::Schema::Result::FeatureInstContact",
  { "foreign.id_feat_inst2" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 feature

Type: belongs_to

Related object: L<Fist::Schema::Result::Feature>

=cut

__PACKAGE__->belongs_to(
  "feature",
  "Fist::Schema::Result::Feature",
  { id => "id_feature" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 seq

Type: belongs_to

Related object: L<Fist::Schema::Result::Seq>

=cut

__PACKAGE__->belongs_to(
  "seq",
  "Fist::Schema::Result::Seq",
  { id => "id_seq" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


=head2 enzymes

Type: many_to_many

Composing rels: L</enzyme_to_feature_insts> -> id_seq

=cut

__PACKAGE__->many_to_many("enzymes", "enzymes_to_feature_insts", "id_seq");

=head2 pmids

Type: many_to_many

Composing rels: L</pmid_to_feature_insts> -> pmid

=cut

__PACKAGE__->many_to_many("pmids", "pmid_to_feature_insts", "pmid");

# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-08-05 15:41:36
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:IGfM6db93iIWsbHAFiG0bg

# You can replace this text with custom code or comments, and it will be preserved on regeneration

=head1 ROLES

 with 'Fist::Interface::FeatureInst';

=cut

with 'Fist::Interface::FeatureInst';

__PACKAGE__->meta->make_immutable;
1;
