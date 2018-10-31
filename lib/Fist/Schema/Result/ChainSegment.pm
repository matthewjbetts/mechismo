use utf8;
package Fist::Schema::Result::ChainSegment;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Fist::Schema::Result::ChainSegment

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

=head1 TABLE: C<ChainSegment>

=cut

__PACKAGE__->table("ChainSegment");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 id_frag

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 chain

  data_type: 'binary'
  is_nullable: 0
  size: 1

=head2 resseq_start

  data_type: 'smallint'
  is_nullable: 0

=head2 icode_start

  data_type: 'binary'
  is_nullable: 0
  size: 1

=head2 resseq_end

  data_type: 'smallint'
  is_nullable: 0

=head2 icode_end

  data_type: 'binary'
  is_nullable: 0
  size: 1

=head2 fist_start

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 fist_len

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
  "id_frag",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "chain",
  { data_type => "binary", is_nullable => 0, size => 1 },
  "resseq_start",
  { data_type => "smallint", is_nullable => 0 },
  "icode_start",
  { data_type => "binary", is_nullable => 0, size => 1 },
  "resseq_end",
  { data_type => "smallint", is_nullable => 0 },
  "icode_end",
  { data_type => "binary", is_nullable => 0, size => 1 },
  "fist_start",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
  "fist_len",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 frag

Type: belongs_to

Related object: L<Fist::Schema::Result::Frag>

=cut

__PACKAGE__->belongs_to(
  "frag",
  "Fist::Schema::Result::Frag",
  { id => "id_frag" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2012-12-20 13:44:33
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:GG2Mm+gVbB+c+xd/EFA/Og

# You can replace this text with custom code or comments, and it will be preserved on regeneration

=head1 ROLES

 with 'Fist::Interface::ChainSegment';

=cut

with 'Fist::Interface::ChainSegment';

sub schema {
    my($self) = @_;

    return $self->result_source->schema;
}

__PACKAGE__->meta->make_immutable;
1;
