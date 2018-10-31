use utf8;
package Fist::Schema::Result::Hsp;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Fist::Schema::Result::Hsp

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

=head1 TABLE: C<Hsp>

=cut

__PACKAGE__->table("Hsp");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 id_seq1

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 id_seq2

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 pcid

  data_type: 'float'
  is_nullable: 0

=head2 a_len

  data_type: 'smallint'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 n_gaps

  data_type: 'smallint'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 start1

  data_type: 'smallint'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 end1

  data_type: 'smallint'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 start2

  data_type: 'smallint'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 end2

  data_type: 'smallint'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 e_value

  data_type: 'double precision'
  is_nullable: 0

=head2 score

  data_type: 'float'
  is_nullable: 0

=head2 id_aln

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "id_seq1",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
  "id_seq2",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
  "pcid",
  { data_type => "float", is_nullable => 0 },
  "a_len",
  { data_type => "smallint", extra => { unsigned => 1 }, is_nullable => 0 },
  "n_gaps",
  { data_type => "smallint", extra => { unsigned => 1 }, is_nullable => 0 },
  "start1",
  { data_type => "smallint", extra => { unsigned => 1 }, is_nullable => 0 },
  "end1",
  { data_type => "smallint", extra => { unsigned => 1 }, is_nullable => 0 },
  "start2",
  { data_type => "smallint", extra => { unsigned => 1 }, is_nullable => 0 },
  "end2",
  { data_type => "smallint", extra => { unsigned => 1 }, is_nullable => 0 },
  "e_value",
  { data_type => "double precision", is_nullable => 0 },
  "score",
  { data_type => "float", is_nullable => 0 },
  "id_aln",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2012-12-20 13:44:35
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:IwK1wlNIfU9N8ria5tC1pw

# You can replace this text with custom code or comments, and it will be preserved on regeneration

=head1 RELATIONS

=head2 seq1

Type: belongs_to

Related object: L<Fist::Schema::Result::Seq>

=cut

__PACKAGE__->belongs_to(
  "seq1",
  "Fist::Schema::Result::Seq",
  { id => "id_seq1" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 seq2

Type: belongs_to

Related object: L<Fist::Schema::Result::Seq>

=cut

__PACKAGE__->belongs_to(
  "seq2",
  "Fist::Schema::Result::Seq",
  { id => "id_seq2" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

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

=head1 ROLES

 with 'Fist::Interface::Hsp';

=cut

with 'Fist::Interface::Hsp';

__PACKAGE__->meta->make_immutable;
1;
