use utf8;
package Fist::Schema::Result::ContactHitInterprets;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Fist::Schema::Result::ContactHitInterprets

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

=head1 TABLE: C<ContactHitInterprets>

=cut

__PACKAGE__->table("ContactHitInterprets");

=head1 ACCESSORS

=head2 id_contact_hit

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 mode

  data_type: 'tinyint'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 rand

  data_type: 'mediumint'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 raw

  data_type: 'double precision'
  is_nullable: 0

=head2 mean

  data_type: 'double precision'
  is_nullable: 0

=head2 sd

  data_type: 'double precision'
  is_nullable: 0

=head2 z

  data_type: 'double precision'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id_contact_hit",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
  "mode",
  { data_type => "tinyint", extra => { unsigned => 1 }, is_nullable => 0 },
  "rand",
  { data_type => "mediumint", extra => { unsigned => 1 }, is_nullable => 0 },
  "raw",
  { data_type => "double precision", is_nullable => 0 },
  "mean",
  { data_type => "double precision", is_nullable => 0 },
  "sd",
  { data_type => "double precision", is_nullable => 0 },
  "z",
  { data_type => "double precision", is_nullable => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2012-12-20 13:44:33
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:GqI75AXSY2no6nsbDjvNIQ

# You can replace this text with custom code or comments, and it will be preserved on regeneration

=head1 ROLES

 with 'Fist::Interface::ContactHitInterprets';

=cut

with 'Fist::Interface::ContactHitInterprets';

__PACKAGE__->meta->make_immutable;
1;
