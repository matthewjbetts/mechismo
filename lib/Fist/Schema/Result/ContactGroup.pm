use utf8;
package Fist::Schema::Result::ContactGroup;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Fist::Schema::Result::ContactGroup

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

=head1 TABLE: C<ContactGroup>

=cut

__PACKAGE__->table("ContactGroup");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 id_parent

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 type

  data_type: 'varchar'
  is_nullable: 0
  size: 50

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "id_parent",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_nullable => 0,
  },
  "type",
  { data_type => "varchar", is_nullable => 0, size => 50 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 contact_to_groups

Type: has_many

Related object: L<Fist::Schema::Result::ContactToGroup>

=cut

__PACKAGE__->has_many(
  "contact_to_groups",
  "Fist::Schema::Result::ContactToGroup",
  { "foreign.id_group" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

# Created by DBIx::Class::Schema::Loader v0.07033 @ 2012-12-20 13:44:35
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:eIqoJaIblP+6LlOOymNANA

# You can replace this text with custom code or comments, and it will be preserved on regeneration

__PACKAGE__->many_to_many('contacts', 'contact_to_groups', 'id_contact');

=head1 ROLES

 with 'Fist::Interface::ContactGroup';

=cut

with 'Fist::Interface::ContactGroup';

__PACKAGE__->meta->make_immutable;
1;
