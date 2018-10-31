use utf8;
package Fist::Schema::Result::Alignment;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Fist::Schema::Result::Alignment

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

=head1 TABLE: C<Alignment>

=cut

__PACKAGE__->table("Alignment");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 method

  data_type: 'enum'
  extra: {list => ["muscle","blastp"]}
  is_nullable: 1

=head2 len

  data_type: 'smallint'
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
  "method",
  {
    data_type => "enum",
    extra => { list => ["muscle", "blastp"] },
    is_nullable => 1,
  },
  "len",
  { data_type => "smallint", extra => { unsigned => 1 }, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 alignment_to_groups

Type: has_many

Related object: L<Fist::Schema::Result::AlignmentToGroup>

=cut

__PACKAGE__->has_many(
  "alignment_to_groups",
  "Fist::Schema::Result::AlignmentToGroup",
  { "foreign.id_aln" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 frag_hits

Type: has_many

Related object: L<Fist::Schema::Result::FragHit>

=cut

__PACKAGE__->has_many(
  "frag_hits",
  "Fist::Schema::Result::FragHit",
  { "foreign.id_aln" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 id_groups

Type: many_to_many

Composing rels: L</alignment_to_groups> -> id_group

=cut

__PACKAGE__->many_to_many("id_groups", "alignment_to_groups", "id_group");


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-01-04 16:44:22
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:ksWQiqvWUxXKkaOgxFHUhA

# You can replace this text with custom code or comments, and it will be preserved on regeneration

=head2 aligned_seqs

Type: has_many

Related object: L<Fist::Schema::Result::AlignedSeq>

=cut

__PACKAGE__->has_many(
  "aligned_seqs",
  "Fist::Schema::Result::AlignedSeq",
  { "foreign.id_aln" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head1 ROLES

 with 'Fist::Interface::Alignment';

=cut

with 'Fist::Interface::Alignment';

=head1 METHODS

=cut

=head2 aseq

 usage   :
 function:
 args    :
 returns :

=cut

sub aseq {
    my($self, $id_seq) = @_;

    my $schema;
    my $key;
    my $aseq;

    #print join("\t", 'ASEQ', $self->id, $id_seq), "\n";
    #$aseq = $self->find_related('aligned_seqs', {id_seq => $id_seq});

    $schema = $self->result_source->schema;
    $key = $self->cache_key('aseq', $id_seq);
    if(defined($aseq = $self->cache->get($key))) {
        $aseq = $schema->thaw($aseq);
    }
    else {
        #print join("\t", 'ASEQ', $self->id, $id_seq), "\n";
        #$aseq = $self->find_related('aligned_seqs', {id_seq => $id_seq});
        $aseq = $schema->resultset('AlignedSeq')->find({id_aln => $self->id, id_seq => $id_seq});
        #(ref($aseq) ne '') or warn("Error: '$aseq' is not a reference");
        $self->cache->set($key, $schema->freeze($aseq));
    }

    return $aseq;
}

=head2 aseqs

 usage   :
 function:
 args    :
 returns :

=cut

sub aseqs {
    my($self) = @_;

    my $schema;
    my $key;
    my $aseqs;
    my $aseq;

    $schema = $self->result_source->schema;
    $key = $self->cache_key('aseqs');
    if(defined($aseqs = $self->cache->get($key))) {
        $aseqs = $schema->thaw($aseqs);
    }
    else {
        $aseqs = {};
        foreach $aseq ($self->aligned_seqs) {
            $aseqs->{$aseq->id_seq} = $aseq;
        }
        #(ref($aseqs) ne '') or warn("Error: '$aseqs' is not a reference");
        $self->cache->set($key, $schema->freeze($aseqs));
    }

    return $aseqs;
}

__PACKAGE__->meta->make_immutable;
1;
