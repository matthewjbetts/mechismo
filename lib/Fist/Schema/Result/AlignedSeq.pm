use utf8;
package Fist::Schema::Result::AlignedSeq;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Fist::Schema::Result::AlignedSeq

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

=head1 TABLE: C<AlignedSeq>

=cut

__PACKAGE__->table("AlignedSeq");

=head1 ACCESSORS

=head2 id_aln

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 id_seq

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 start

  data_type: 'smallint'
  default_value: 1
  extra: {unsigned => 1}
  is_nullable: 0

=head2 end

  data_type: 'smallint'
  default_value: 0
  extra: {unsigned => 1}
  is_nullable: 0

=head2 _edit_str

  data_type: 'text'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id_aln",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
  "id_seq",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
  "start",
  {
    data_type => "smallint",
    default_value => 1,
    extra => { unsigned => 1 },
    is_nullable => 0,
  },
  "end",
  {
    data_type => "smallint",
    default_value => 0,
    extra => { unsigned => 1 },
    is_nullable => 0,
  },
  "_edit_str",
  { data_type => "text", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id_aln>

=item * L</id_seq>

=back

=cut

__PACKAGE__->set_primary_key("id_aln", "id_seq");


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2012-12-20 13:44:33
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:QkCVeB9VaLohQVOohIMtjw

# You can replace this text with custom code or comments, and it will be preserved on regeneration

=head1 RELATIONS

=head2 aln

Type: belongs_to

Related object: L<Fist::Schema::Result::Alignment>

=cut

__PACKAGE__->belongs_to(
  "aln",
  "Fist::Schema::Result::Alignment",
  { id => "id_aln" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 seq

Type: belongs_to

Related object: L<Fist::Schema::Result::Seq>

=cut

__PACKAGE__->belongs_to(
  "seq",
  "Fist::Schema::Result::Seq",
  { id => "id_seq" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head1 METHODS

=cut

=head1 ROLES

 with 'Fist::Interface::AlignedSeq';

=cut

with 'Fist::Interface::AlignedSeq';

__PACKAGE__->meta->make_immutable;
1;
