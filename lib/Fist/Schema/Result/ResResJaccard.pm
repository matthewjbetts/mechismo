use utf8;
package Fist::Schema::Result::ResResJaccard;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Fist::Schema::Result::ResResJaccard

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

=head1 TABLE: C<ResResJaccard>

=cut

__PACKAGE__->table("ResResJaccard");

=head1 ACCESSORS

=head2 id_frag_inst_a1

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 id_frag_inst_b1

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 id_frag_inst_a2

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 id_frag_inst_b2

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 intersection

  data_type: 'smallint'
  default_value: 0
  extra: {unsigned => 1}
  is_nullable: 0

=head2 aln_n_resres1

  data_type: 'smallint'
  default_value: 0
  extra: {unsigned => 1}
  is_nullable: 0

=head2 aln_n_resres2

  data_type: 'smallint'
  default_value: 0
  extra: {unsigned => 1}
  is_nullable: 0

=head2 aln_union

  data_type: 'smallint'
  default_value: 0
  extra: {unsigned => 1}
  is_nullable: 0

=head2 aln_jaccard

  data_type: 'float'
  default_value: 0
  is_nullable: 0

=head2 full_union

  data_type: 'smallint'
  default_value: 0
  extra: {unsigned => 1}
  is_nullable: 0

=head2 full_jaccard

  data_type: 'float'
  default_value: 0
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id_frag_inst_a1",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
  "id_frag_inst_b1",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
  "id_frag_inst_a2",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
  "id_frag_inst_b2",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
  "intersection",
  {
    data_type => "smallint",
    default_value => 0,
    extra => { unsigned => 1 },
    is_nullable => 0,
  },
  "aln_n_resres1",
  {
    data_type => "smallint",
    default_value => 0,
    extra => { unsigned => 1 },
    is_nullable => 0,
  },
  "aln_n_resres2",
  {
    data_type => "smallint",
    default_value => 0,
    extra => { unsigned => 1 },
    is_nullable => 0,
  },
  "aln_union",
  {
    data_type => "smallint",
    default_value => 0,
    extra => { unsigned => 1 },
    is_nullable => 0,
  },
  "aln_jaccard",
  { data_type => "float", default_value => 0, is_nullable => 0 },
  "full_union",
  {
    data_type => "smallint",
    default_value => 0,
    extra => { unsigned => 1 },
    is_nullable => 0,
  },
  "full_jaccard",
  { data_type => "float", default_value => 0, is_nullable => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2012-12-20 13:44:35
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:+jXbIujx+2Df0NFCeNN5mA

# You can replace this text with custom code or comments, and it will be preserved on regeneration

=head1 RELATIONS

=cut

=head2 frag_inst_a1

Type: belongs_to

Related object: L<Fist::Schema::Result::FragInst>

=cut

__PACKAGE__->belongs_to(
  "frag_inst_a1",
  "Fist::Schema::Result::FragInst",
  { id => "id_frag_inst_a1" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 frag_inst_b1

Type: belongs_to

Related object: L<Fist::Schema::Result::FragInst>

=cut

__PACKAGE__->belongs_to(
  "frag_inst_b1",
  "Fist::Schema::Result::FragInst",
  { id => "id_frag_inst_b1" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 frag_inst_a2

Type: belongs_to

Related object: L<Fist::Schema::Result::FragInst>

=cut

__PACKAGE__->belongs_to(
  "frag_inst_a2",
  "Fist::Schema::Result::FragInst",
  { id => "id_frag_inst_a2" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 frag_inst_b2

Type: belongs_to

Related object: L<Fist::Schema::Result::FragInst>

=cut

__PACKAGE__->belongs_to(
  "frag_inst_b2",
  "Fist::Schema::Result::FragInst",
  { id => "id_frag_inst_b2" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head1 ROLES

 with 'Fist::Interface::ResResJaccard';

=cut

with 'Fist::Interface::ResResJaccard';

__PACKAGE__->meta->make_immutable;
1;
