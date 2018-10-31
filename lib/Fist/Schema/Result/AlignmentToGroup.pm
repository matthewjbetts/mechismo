use utf8;
package Fist::Schema::Result::AlignmentToGroup;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Fist::Schema::Result::AlignmentToGroup

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

=head1 TABLE: C<AlignmentToGroup>

=cut

__PACKAGE__->table("AlignmentToGroup");

=head1 ACCESSORS

=head2 id_aln

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 id_group

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id_aln",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "id_group",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</id_group>

=item * L</id_aln>

=back

=cut

__PACKAGE__->set_primary_key("id_group", "id_aln");

=head1 RELATIONS

=head2 id_aln

Type: belongs_to

Related object: L<Fist::Schema::Result::Alignment>

=cut

__PACKAGE__->belongs_to(
  "id_aln",
  "Fist::Schema::Result::Alignment",
  { id => "id_aln" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 id_group

Type: belongs_to

Related object: L<Fist::Schema::Result::SeqGroup>

=cut

__PACKAGE__->belongs_to(
  "id_group",
  "Fist::Schema::Result::SeqGroup",
  { id => "id_group" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2012-12-20 13:44:33
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:IKxjQRscvvlHKjACOop+sg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
