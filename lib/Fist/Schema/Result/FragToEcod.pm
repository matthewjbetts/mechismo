use utf8;
package Fist::Schema::Result::FragToEcod;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Fist::Schema::Result::FragToEcod

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

=head1 TABLE: C<FragToEcod>

=cut

__PACKAGE__->table("FragToEcod");

=head1 ACCESSORS

=head2 id_frag

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 id_ecod

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 type

  data_type: 'enum'
  extra: {list => ["ecod","match"]}
  is_nullable: 0

=head2 ac

  data_type: 'varchar'
  is_nullable: 0
  size: 30

=cut

__PACKAGE__->add_columns(
  "id_frag",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "id_ecod",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "type",
  {
    data_type => "enum",
    extra => {
      list => [
        "ecod",
        "match",
      ],
    },
    is_nullable => 0,
  },
  "ac",
  { data_type => "varchar", default_value => '', is_nullable => 0, size => 30 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id_frag>

=item * L</id_ecod>

=back

=cut

__PACKAGE__->set_primary_key("id_frag", "id_ecod");

=head1 RELATIONS

=head2 id_frag

Type: belongs_to

Related object: L<Fist::Schema::Result::Frag>

=cut

__PACKAGE__->belongs_to(
  "id_frag",
  "Fist::Schema::Result::Frag",
  { id => "id_frag" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 id_ecod

Type: belongs_to

Related object: L<Fist::Schema::Result::Ecod>

=cut

__PACKAGE__->belongs_to(
  "id_ecod",
  "Fist::Schema::Result::Ecod",
  { id => "id_ecod" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2012-12-20 13:44:34
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:jwOC1+KP5uqKTc73zeT1iQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
