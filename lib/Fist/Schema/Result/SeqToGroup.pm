use utf8;
package Fist::Schema::Result::SeqToGroup;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Fist::Schema::Result::SeqToGroup

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

=head1 TABLE: C<SeqToGroup>

=cut

__PACKAGE__->table("SeqToGroup");

=head1 ACCESSORS

=head2 id_seq

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 id_group

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 rep

  data_type: 'tinyint'
  default_value: 0
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id_seq",
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
  "rep",
  { data_type => "tinyint", default_value => 0, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id_group>

=item * L</id_seq>

=back

=cut

__PACKAGE__->set_primary_key("id_group", "id_seq");

=head1 RELATIONS

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

=head2 id_seq

Type: belongs_to

Related object: L<Fist::Schema::Result::Seq>

=cut

__PACKAGE__->belongs_to(
  "id_seq",
  "Fist::Schema::Result::Seq",
  { id => "id_seq" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2012-12-20 13:44:35
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:yUJHGUHMCNGS0Sirwi0d5g

# You can replace this text with custom code or comments, and it will be preserved on regeneration

sub group {
    my($self) = @_;

    return $self->id_group;
}

sub seq {
    my($self) = @_;

    return $self->id_seq;
}

__PACKAGE__->meta->make_immutable;
1;
