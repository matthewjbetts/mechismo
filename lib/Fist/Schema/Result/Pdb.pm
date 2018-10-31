use utf8;
package Fist::Schema::Result::Pdb;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Fist::Schema::Result::Pdb

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

=head1 TABLE: C<Pdb>

=cut

__PACKAGE__->table("Pdb");

=head1 ACCESSORS

=head2 idcode

  data_type: 'char'
  is_nullable: 0
  size: 4

=head2 title

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 resolution

  data_type: 'float'
  default_value: 99999
  is_nullable: 0

=head2 depdate

  data_type: 'date'
  datetime_undef_if_invalid: 1
  default_value: '9999-12-31'
  is_nullable: 0

=head2 updated

  data_type: 'date'
  datetime_undef_if_invalid: 1
  default_value: '9999-12-31'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "idcode",
  { data_type => "char", is_nullable => 0, size => 4 },
  "title",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "resolution",
  { data_type => "float", default_value => 99999, is_nullable => 0 },
  "depdate",
  {
    data_type => "date",
    datetime_undef_if_invalid => 1,
    default_value => "9999-12-31",
    is_nullable => 0,
  },
  "updated",
  {
    data_type => "date",
    datetime_undef_if_invalid => 1,
    default_value => "9999-12-31",
    is_nullable => 0,
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</idcode>

=back

=cut

__PACKAGE__->set_primary_key("idcode");

=head1 RELATIONS

=head2 expdtas

Type: has_many

Related object: L<Fist::Schema::Result::Expdta>

=cut

__PACKAGE__->has_many(
  "expdtas",
  "Fist::Schema::Result::Expdta",
  { "foreign.idcode" => "self.idcode" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 frags

Type: has_many

Related object: L<Fist::Schema::Result::Frag>

=cut

__PACKAGE__->has_many(
  "frags",
  "Fist::Schema::Result::Frag",
  { "foreign.idcode" => "self.idcode" },
  { cascade_copy => 0, cascade_delete => 0 },
);

# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-08-05 15:08:48
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:0biL+iKOc6hp+++naGolBw

# You can replace this text with custom code or comments, and it will be preserved on regeneration

=head1 ROLES

 with 'Fist::Interface::Pdb';

=cut

with 'Fist::Interface::Pdb';

__PACKAGE__->meta->make_immutable;
1;
