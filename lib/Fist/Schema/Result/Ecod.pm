use utf8;
package Fist::Schema::Result::Ecod;

=head1 NAME

Fist::Schema::Result::Ecod

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

=head1 TABLE: C<Ecod>

=cut

__PACKAGE__->table("Ecod");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 x

  data_type: 'smallint'
  extra: {unsigned => 1}
  is_nullable: 1

=head2 h

  data_type: 'smallint'
  extra: {unsigned => 1}
  is_nullable: 1

=head2 t

  data_type: 'smallint'
  extra: {unsigned => 1}
  is_nullable: 1

=head2 f

  data_type: 'smallint'
  extra: {unsigned => 1}
  is_nullable: 1

=head2 description

  data_type: 'name'
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
  "x",
  { data_type => "smallint", extra => { unsigned => 1 }, is_nullable => 1 },
  "h",
  { data_type => "smallint", extra => { unsigned => 1 }, is_nullable => 1 },
  "t",
  { data_type => "smallint", extra => { unsigned => 1 }, is_nullable => 1 },
  "f",
  { data_type => "smallint", extra => { unsigned => 1 }, is_nullable => 1 },
  "name",
  { data_type => "text", is_nullable => 1},
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 frag_to_ecods

Type: has_many

Related object: L<Fist::Schema::Result::FragToEcod>

=cut

__PACKAGE__->has_many(
  "frag_to_ecods",
  "Fist::Schema::Result::FragToEcod",
  { "foreign.id_ecod" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head1 ROLES

=cut

with 'Fist::Interface::Ecod';

__PACKAGE__->meta->make_immutable;
1;
