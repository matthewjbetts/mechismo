use utf8;
package Fist::Schema::Result::GoTerm;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Fist::Schema::Result::GoTerm

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

=head1 TABLE: C<GoTerm>

=cut

__PACKAGE__->table("GoTerm");

=head1 ACCESSORS

=head2 id

  data_type: 'char'
  is_nullable: 0
  size: 10

=head2 namespace

  data_type: 'enum'
  extra: {list => ["biological_process","molecular_function","cellular_component"]}
  is_nullable: 1

=head2 name

  data_type: 'varchar'
  is_nullable: 1
  size: 250

=head2 def

  data_type: 'text'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "char", is_nullable => 0, size => 10 },
  "namespace",
  {
    data_type => "enum",
    extra => {
      list => [
        "biological_process",
        "molecular_function",
        "cellular_component",
      ],
    },
    is_nullable => 1,
  },
  "name",
  { data_type => "varchar", is_nullable => 1, size => 250 },
  "def",
  { data_type => "text", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 go_annotations

Type: has_many

Related object: L<Fist::Schema::Result::GoAnnotation>

=cut

__PACKAGE__->has_many(
  "go_annotations",
  "Fist::Schema::Result::GoAnnotation",
  { "foreign.id_term" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2012-12-20 13:44:35
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:YYiILvkDmgNs06X51DejbQ

# You can replace this text with custom code or comments, and it will be preserved on regeneration

=head1 ROLES

 with 'Fist::Interface::GoTerm';

=cut

with 'Fist::Interface::GoTerm';

__PACKAGE__->meta->make_immutable;
1;
