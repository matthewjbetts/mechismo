use utf8;
package Fist::Schema::Result::GoAnnotation;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Fist::Schema::Result::GoAnnotation

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

=head1 TABLE: C<GoAnnotation>

=cut

__PACKAGE__->table("GoAnnotation");

=head1 ACCESSORS

=head2 id_seq

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 id_term

  data_type: 'char'
  is_foreign_key: 1
  is_nullable: 0
  size: 10

=head2 subset

  data_type: 'varchar'
  default_value: 'none'
  is_nullable: 0
  size: 50

=head2 evidence_code

  data_type: 'varchar'
  is_nullable: 0
  size: 3

=cut

__PACKAGE__->add_columns(
  "id_seq",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "id_term",
  { data_type => "char", is_foreign_key => 1, is_nullable => 0, size => 10 },
  "subset",
  {
    data_type => "varchar",
    default_value => "none",
    is_nullable => 0,
    size => 50,
  },
  "evidence_code",
  { data_type => "varchar", is_nullable => 0, size => 3 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id_seq>

=item * L</id_term>

=item * L</subset>

=item * L</evidence_code>

=back

=cut

__PACKAGE__->set_primary_key("id_seq", "id_term", "subset", "evidence_code");

=head1 RELATIONS

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

=head2 term

Type: belongs_to

Related object: L<Fist::Schema::Result::GoTerm>

=cut

__PACKAGE__->belongs_to(
  "term",
  "Fist::Schema::Result::GoTerm",
  { id => "id_term" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2012-12-20 13:44:34
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:wYICJAJ6+FCdHxyzwn7Zjw

# You can replace this text with custom code or comments, and it will be preserved on regeneration

=head1 ROLES

 with 'Fist::Interface::GoAnnotation';

=cut

with 'Fist::Interface::GoAnnotation';

__PACKAGE__->meta->make_immutable;
1;
