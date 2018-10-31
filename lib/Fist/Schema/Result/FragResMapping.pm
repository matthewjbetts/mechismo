use utf8;
package Fist::Schema::Result::FragResMapping;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Fist::Schema::Result::FragResMapping

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

=head1 TABLE: C<FragResMapping>

=cut

__PACKAGE__->table("FragResMapping");

=head1 ACCESSORS

=head2 id_frag

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 fist

  data_type: 'smallint'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 chain

  data_type: 'binary'
  is_nullable: 0
  size: 1

=head2 resseq

  data_type: 'smallint'
  is_nullable: 0

=head2 icode

  data_type: 'binary'
  is_nullable: 0
  size: 1

=cut

=head2 res3

  data_type: 'char'
  is_nullable: 0
  size: 3

=head2 res1

  data_type: 'char'
  is_nullable: 0
  size: 1

=cut

__PACKAGE__->add_columns(
  "id_frag",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
  "fist",
  { data_type => "smallint", extra => { unsigned => 1 }, is_nullable => 0 },
  "chain",
  { data_type => "binary", is_nullable => 0, size => 1 },
  "resseq",
  { data_type => "smallint", is_nullable => 0 },
  "icode",
  { data_type => "binary", is_nullable => 0, size => 1 },
  "res3",
  { data_type => "char", is_nullable => 0, size => 3 },
  "res1",
  { data_type => "char", is_nullable => 0, size => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id_frag>

=item * L</fist>

=back

=cut

__PACKAGE__->set_primary_key("id_frag", "fist");


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2012-12-20 13:44:34
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:ka8iOqlS8CUHMx6Q6eTIcQ

=head1 ROLES

 with 'Fist::Interface::FragResMapping';

=cut

with 'Fist::Interface::FragResMapping';


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
