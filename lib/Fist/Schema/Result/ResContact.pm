use utf8;
package Fist::Schema::Result::ResContact;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Fist::Schema::Result::ResContact

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

=head1 TABLE: C<ResContact>

=cut

__PACKAGE__->table("ResContact");

=head1 ACCESSORS

=head2 id_contact

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 bond_type

  accessor: 'bond_type'
  data_type: 'smallint'
  extra: {unsigned => 1}
  default_value: 0
  is_nullable: 0

=head2 chain1

  data_type: 'binary'
  is_nullable: 0
  size: 1

=head2 resseq1

  data_type: 'smallint'
  is_nullable: 0

=head2 icode1

  data_type: 'binary'
  is_nullable: 0
  size: 1

=head2 chain2

  data_type: 'binary'
  is_nullable: 0
  size: 1

=head2 resseq2

  data_type: 'smallint'
  is_nullable: 0

=head2 icode2

  data_type: 'binary'
  is_nullable: 0
  size: 1

=cut

__PACKAGE__->add_columns(
  "id_contact",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
  "bond_type",
  {
    data_type     => "smallint",
    extra         => {unsigned => 1},
    is_nullable   => 0,
  },
  "chain1",
  { data_type => "binary", is_nullable => 0, size => 1 },
  "resseq1",
  { data_type => "smallint", is_nullable => 0 },
  "icode1",
  { data_type => "binary", is_nullable => 0, size => 1 },
  "chain2",
  { data_type => "binary", is_nullable => 0, size => 1 },
  "resseq2",
  { data_type => "smallint", is_nullable => 0 },
  "icode2",
  { data_type => "binary", is_nullable => 0, size => 1 },
);

# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-06-30 23:59:00
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:dpHCyT3QIAtm7EWpUs+X3A

# You can replace this text with custom code or comments, and it will be preserved on regeneration

=head2 contact

Type: belongs_to

Related object: L<Fist::Schema::Result::Contact>

=cut

__PACKAGE__->belongs_to(
  "contact",
  "Fist::Schema::Result::Contact",
  { id => "id_contact" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head1 ROLES

 with 'Fist::Interface::ResContact';

=cut

with 'Fist::Interface::ResContact';

__PACKAGE__->meta->make_immutable;
1;
