use utf8;
package Fist::Schema::Result::FeatureContact;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Fist::Schema::Result::FeatureContact

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

=head1 TABLE: C<FeatureContact>

=cut

__PACKAGE__->table("FeatureContact");

=head1 ACCESSORS

=head2 id_feat1

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 id_feat2

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id_feat1",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "id_feat2",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</id_feat1>

=item * L</id_feat2>

=back

=cut

__PACKAGE__->set_primary_key("id_feat1", "id_feat2");

=head1 RELATIONS

=head2 feature1

Type: belongs_to

Related object: L<Fist::Schema::Result::Feature>

=cut

__PACKAGE__->belongs_to(
  "feature1",
  "Fist::Schema::Result::Feature",
  { id => "id_feat1" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 feature2

Type: belongs_to

Related object: L<Fist::Schema::Result::Feature>

=cut

__PACKAGE__->belongs_to(
  "feature2",
  "Fist::Schema::Result::Feature",
  { id => "id_feat2" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-08-06 11:46:36
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:tCNKcbLC47enSjmyf1k3Cg

# You can replace this text with custom code or comments, and it will be preserved on regeneration

=head1 ROLES

 with 'Fist::Interface::FeatureContact';

=cut

with 'Fist::Interface::FeatureContact';

__PACKAGE__->meta->make_immutable;
1;
