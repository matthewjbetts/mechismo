use utf8;
package Fist::Schema::Result::FeatureInstContact;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Fist::Schema::Result::FeatureInstContact

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

=head1 TABLE: C<FeatureInstContact>

=cut

__PACKAGE__->table("FeatureInstContact");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 id_frag_inst1

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 id_frag_inst2

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 id_feat_inst1

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 id_feat_inst2

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 n_resres

  data_type: 'smallint'
  extra: {unsigned => 1}
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
  "id_frag_inst1",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "id_frag_inst2",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "id_feat_inst1",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "id_feat_inst2",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "n_resres",
  { data_type => "smallint", extra => { unsigned => 1 }, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 feat_inst1

Type: belongs_to

Related object: L<Fist::Schema::Result::FeatureInst>

=cut

__PACKAGE__->belongs_to(
  "feat_inst1",
  "Fist::Schema::Result::FeatureInst",
  { id => "id_feat_inst1" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 feat_inst2

Type: belongs_to

Related object: L<Fist::Schema::Result::FeatureInst>

=cut

__PACKAGE__->belongs_to(
  "feat_inst2",
  "Fist::Schema::Result::FeatureInst",
  { id => "id_feat_inst2" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 frag_inst1

Type: belongs_to

Related object: L<Fist::Schema::Result::FragInst>

=cut

__PACKAGE__->belongs_to(
  "frag_inst1",
  "Fist::Schema::Result::FragInst",
  { id => "id_frag_inst1" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 frag_inst2

Type: belongs_to

Related object: L<Fist::Schema::Result::FragInst>

=cut

__PACKAGE__->belongs_to(
  "frag_inst2",
  "Fist::Schema::Result::FragInst",
  { id => "id_frag_inst2" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-08-05 15:41:36
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:ZRAA2S1ZbRLVlQOYgF7bIA

# You can replace this text with custom code or comments, and it will be preserved on regeneration

=head1 ROLES

 with 'Fist::Interface::FeatureInstContact';

=cut

with 'Fist::Interface::FeatureInstContact';

__PACKAGE__->meta->make_immutable;
1;
