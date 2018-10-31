use utf8;
package Fist::Schema::Result::Taxon;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Fist::Schema::Result::Taxon

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

=head1 TABLE: C<Taxon>

=cut

__PACKAGE__->table("Taxon");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 id_parent

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 scientific_name

  data_type: 'varchar'
  default_value: (empty string)
  is_nullable: 0
  size: 120

=head2 common_name

  data_type: 'varchar'
  default_value: (empty string)
  is_nullable: 0
  size: 70

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
  "id_parent",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
  "scientific_name",
  { data_type => "varchar", default_value => "", is_nullable => 0, size => 120 },
  "common_name",
  { data_type => "varchar", default_value => "", is_nullable => 0, size => 70 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 seq_to_taxons

Type: has_many

Related object: L<Fist::Schema::Result::SeqToTaxon>

=cut

__PACKAGE__->has_many(
  "seq_to_taxons",
  "Fist::Schema::Result::SeqToTaxon",
  { "foreign.id_taxon" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 id_seqs

Type: many_to_many

Composing rels: L</seq_to_taxons> -> id_seq

=cut

__PACKAGE__->many_to_many("id_seqs", "seq_to_taxons", "id_seq");


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2012-12-20 13:44:35
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:eUXrTIAe7EJaVa4isPE+nA

# You can replace this text with custom code or comments, and it will be preserved on regeneration

=head1 ROLES

 with 'Fist::Interface::Taxon';

=cut

with 'Fist::Interface::Taxon';

=head1 METHODS

=cut

=head2 child_ids

=cut

sub child_ids {
    my($self) = @_;

    my $dbh;
    my $query;
    my $sth;
    my $table;
    my $row;
    my $ids;
    my @children;
    my $i;
    my $id;

    $dbh = $self->result_source->schema->storage->dbh;
    $query = 'SELECT id, scientific_name FROM Taxon WHERE id_parent = ?';
    $sth = $dbh->prepare($query);

    @children = ();
    $id = $self->id;
    $i = -1;
    while(defined($id)) {
        $sth->execute($id);
        $table = $sth->fetchall_arrayref;
        foreach $row (@{$table}) {
            push @children, $row->[0];
        }
        $id = $children[++$i];
    }

    return @children;
}

__PACKAGE__->meta->make_immutable;
1;
