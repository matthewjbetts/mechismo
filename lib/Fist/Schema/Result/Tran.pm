use utf8;
package Fist::Schema::Result::Tran;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Fist::Schema::Result::Tran

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

=head1 TABLE: C<Tran>

=cut

__PACKAGE__->table("Tran");

=head1 ACCESSORS

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

=head2 pcid

  data_type: 'smallint'
  default_value: 0
  extra: {unsigned => 1}
  is_nullable: 0

=head2 sc

  data_type: 'float'
  is_nullable: 0

=head2 rmsd

  data_type: 'float'
  is_nullable: 0

=head2 r11

  data_type: 'float'
  is_nullable: 0

=head2 r12

  data_type: 'float'
  is_nullable: 0

=head2 r13

  data_type: 'float'
  is_nullable: 0

=head2 v1

  data_type: 'float'
  is_nullable: 0

=head2 r21

  data_type: 'float'
  is_nullable: 0

=head2 r22

  data_type: 'float'
  is_nullable: 0

=head2 r23

  data_type: 'float'
  is_nullable: 0

=head2 v2

  data_type: 'float'
  is_nullable: 0

=head2 r31

  data_type: 'float'
  is_nullable: 0

=head2 r32

  data_type: 'float'
  is_nullable: 0

=head2 r33

  data_type: 'float'
  is_nullable: 0

=head2 v3

  data_type: 'float'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
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
  "pcid",
  {
    data_type => "smallint",
    default_value => 0,
    extra => { unsigned => 1 },
    is_nullable => 0,
  },
  "sc",
  { data_type => "float", is_nullable => 0 },
  "rmsd",
  { data_type => "float", is_nullable => 0 },
  "r11",
  { data_type => "float", is_nullable => 0 },
  "r12",
  { data_type => "float", is_nullable => 0 },
  "r13",
  { data_type => "float", is_nullable => 0 },
  "v1",
  { data_type => "float", is_nullable => 0 },
  "r21",
  { data_type => "float", is_nullable => 0 },
  "r22",
  { data_type => "float", is_nullable => 0 },
  "r23",
  { data_type => "float", is_nullable => 0 },
  "v2",
  { data_type => "float", is_nullable => 0 },
  "r31",
  { data_type => "float", is_nullable => 0 },
  "r32",
  { data_type => "float", is_nullable => 0 },
  "r33",
  { data_type => "float", is_nullable => 0 },
  "v3",
  { data_type => "float", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id_frag_inst1>

=item * L</id_frag_inst2>

=back

=cut

__PACKAGE__->set_primary_key("id_frag_inst1", "id_frag_inst2");

=head1 RELATIONS

=head2 id_frag_inst1

Type: belongs_to

Related object: L<Fist::Schema::Result::FragInst>

=cut

__PACKAGE__->belongs_to(
  "id_frag_inst1",
  "Fist::Schema::Result::FragInst",
  { id => "id_frag_inst1" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 id_frag_inst2

Type: belongs_to

Related object: L<Fist::Schema::Result::FragInst>

=cut

__PACKAGE__->belongs_to(
  "id_frag_inst2",
  "Fist::Schema::Result::FragInst",
  { id => "id_frag_inst2" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2012-12-20 13:44:35
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:965tOMVixFPQFWlDt1uKRg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
