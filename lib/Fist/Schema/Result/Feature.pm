use utf8;
package Fist::Schema::Result::Feature;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Fist::Schema::Result::Feature

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

=head1 TABLE: C<Feature>

=cut

__PACKAGE__->table("Feature");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 source

  data_type: 'varchar'
  is_nullable: 0
  size: 20

=head2 ac_src

  data_type: 'varchar'
  is_nullable: 0
  size: 30

=head2 id_src

  data_type: 'varchar'
  is_nullable: 0
  size: 30

=head2 type

  data_type: 'varchar'
  is_nullable: 0
  size: 30

=head2 regex

  data_type: 'varchar'
  is_nullable: 1
  size: 200

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
  "source",
  { data_type => "varchar", is_nullable => 0, size => 20 },
  "ac_src",
  { data_type => "varchar", is_nullable => 0, size => 30 },
  "id_src",
  { data_type => "varchar", is_nullable => 0, size => 30 },
  "type",
  { data_type => "varchar", is_nullable => 0, size => 30 },
  "regex",
  { data_type => "varchar", is_nullable => 1, size => 200 },
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

=head2 feature_contact_id_feat1s

Type: has_many

Related object: L<Fist::Schema::Result::FeatureContact>

=cut

__PACKAGE__->has_many(
  "feature_contact_id_feat1s",
  "Fist::Schema::Result::FeatureContact",
  { "foreign.id_feat1" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 feature_contact_id_feat2s

Type: has_many

Related object: L<Fist::Schema::Result::FeatureContact>

=cut

__PACKAGE__->has_many(
  "feature_contact_id_feat2s",
  "Fist::Schema::Result::FeatureContact",
  { "foreign.id_feat2" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 feature_insts

Type: has_many

Related object: L<Fist::Schema::Result::FeatureInst>

=cut

__PACKAGE__->has_many(
  "feature_insts",
  "Fist::Schema::Result::FeatureInst",
  { "foreign.id_feature" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 id_feat1s

Type: many_to_many

Composing rels: L</feature_contact_id_feat1s> -> id_feat1

=cut

__PACKAGE__->many_to_many("id_feat1s", "feature_contact_id_feat1s", "id_feat1");

=head2 id_feat2s

Type: many_to_many

Composing rels: L</feature_contact_id_feat1s> -> id_feat2

=cut

__PACKAGE__->many_to_many("id_feat2s", "feature_contact_id_feat1s", "id_feat2");


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-08-06 11:46:36
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:KyTdFjelLiv3caPNOR8rJQ

# You can replace this text with custom code or comments, and it will be preserved on regeneration

=head1 ROLES

 with 'Fist::Interface::Feature';

=cut

with 'Fist::Interface::Feature';


__PACKAGE__->meta->make_immutable;
1;
