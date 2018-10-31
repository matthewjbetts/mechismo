use utf8;
package Fist::Schema::Result::Frag;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Fist::Schema::Result::Frag

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

=head1 TABLE: C<Frag>

=cut

__PACKAGE__->table("Frag");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 idcode

  data_type: 'char'
  is_foreign_key: 1
  is_nullable: 0
  size: 4

=head2 id_seq

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 fullchain

  data_type: 'tinyint'
  default_value: 0
  is_nullable: 0

=head2 description

  data_type: 'text'
  is_nullable: 0

=head2 chemical_type

  data_type: 'varchar'
  is_nullable: 0
  size: 10

=head2 dom

  data_type: 'varbinary'
  is_nullable: 0
  size: 255

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "idcode",
  { data_type => "char", is_foreign_key => 1, is_nullable => 0, size => 4 },
  "id_seq",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_nullable => 0,
  },
  "fullchain",
  { data_type => "tinyint", default_value => 0, is_nullable => 0 },
  "description",
  { data_type => "text", is_nullable => 0 },
  "chemical_type", { data_type => "varchar", is_nullable => 1, size => 10 },
  "dom",
  { data_type => "varbinary", is_nullable => 0, size => 255 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 chain_segments

Type: has_many

Related object: L<Fist::Schema::Result::ChainSegment>

=cut

__PACKAGE__->has_many(
  "chain_segments",
  "Fist::Schema::Result::ChainSegment",
  { "foreign.id_frag" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 frag_insts

Type: has_many

Related object: L<Fist::Schema::Result::FragInst>

=cut

__PACKAGE__->has_many(
  "frag_insts",
  "Fist::Schema::Result::FragInst",
  { "foreign.id_frag" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 frag_to_groups

Type: has_many

Related object: L<Fist::Schema::Result::FragToGroup>

=cut

__PACKAGE__->has_many(
  "frag_to_groups",
  "Fist::Schema::Result::FragToGroup",
  { "foreign.id_frag" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 frag_to_scops

Type: has_many

Related object: L<Fist::Schema::Result::FragToScop>

=cut

__PACKAGE__->has_many(
  "frag_to_scops",
  "Fist::Schema::Result::FragToScop",
  { "foreign.id_frag" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 frag_to_seq_groups

Type: has_many

Related object: L<Fist::Schema::Result::FragToSeqGroup>

=cut

__PACKAGE__->has_many(
  "frag_to_seq_groups",
  "Fist::Schema::Result::FragToSeqGroup",
  { "foreign.id_frag" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 pdb

Type: belongs_to

Related object: L<Fist::Schema::Result::Pdb>

=cut

__PACKAGE__->belongs_to(
  "pdb",
  "Fist::Schema::Result::Pdb",
  { idcode => "idcode" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 id_groups

Type: many_to_many

Composing rels: L</frag_to_seq_groups> -> id_group

=cut

__PACKAGE__->many_to_many("id_groups", "frag_to_seq_groups", "id_group");


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2012-12-20 13:44:34
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:2C5o7aOKGVIpRdu5lFm+uQ

# You can replace this text with custom code or comments, and it will be preserved on regeneration

use CHI;

__PACKAGE__->many_to_many('seq_groups', 'frag_to_seq_groups', 'id_group');
__PACKAGE__->many_to_many('frag_groups', 'frag_to_groups', 'id_group');
__PACKAGE__->many_to_many('scops', 'frag_to_scops', 'id_scop');

sub schema {
    my($self) = @_;

    return $self->result_source->schema;
}

=head2 fist_seq

 usage   :
 function:
 args    :
 returns :

=cut

has 'fist_seq' => (is => 'rw', isa => 'Any'); # FIXME - why doesn't Fist::Interface::Seq work here?

around 'fist_seq' => sub {
    my($orig, $self, $seq) = @_;

    if(defined($seq)) {
        $self->$orig($seq);
    }
    elsif(!defined($seq = $self->$orig)) {
        $seq = $self->_get_seq('fist');
        $self->$orig($seq);
    }

    return $seq;
};

=head2 interprets_seq

 usage   :
 function:
 args    :
 returns :

=cut

has 'interprets_seq' => (is => 'rw', isa => 'Any'); # FIXME - why doesn't Fist::Interface::Seq work here?

around 'interprets_seq' => sub {
    my($orig, $self, $seq) = @_;

    if(defined($seq)) {
        $self->$orig($seq);
    }
    elsif(!defined($seq = $self->$orig)) {
        $seq = $self->_get_seq('interprets');
        $self->$orig($seq);
    }

    return $seq;
};

=head2 aln

 usage   :
 function:
 args    :
 returns :

=cut

has 'aln' => (is => 'rw', isa => 'Any');

around 'aln' => sub {
    my($orig, $self, $aln) = @_;

    my $dbh;
    my $query;
    my $sth;
    my $table;
    my $id_aln;

    if(defined($aln)) {
        $self->$orig($aln);
    }
    elsif(!defined($aln = $self->$orig)) {
        # FIXME - the following is probably slow. However, it seems too  complicated to use resultset->search directly.

        $dbh = $self->schema->storage->dbh;
        $query = <<END;
SELECT c.id_aln
FROM   FragToSeqGroup   AS a,
       SeqGroup         AS b,
       AlignmentToGroup AS c
WHERE  a.id_frag = ?
AND    b.id = a.id_group
AND    b.type = 'frag'
AND    c.id_group = b.id
END
        $sth = $dbh->prepare($query);
        $sth->execute($self->id);
        $table = $sth->fetchall_arrayref;
        if(@{$table} == 1) {
            $id_aln = $table->[0]->[0];
            $aln = $self->schema->resultset('Alignment')->search({id => $id_aln})->first;
            $self->$orig($aln);
        }
    }

    return $aln;
};

=head2 _get_seq

 usage   :
 function:
 args    :
 returns :

=cut

sub _get_seq {
    my($self, $source) = @_;

    my $cache_key;
    my $dbh;
    my $query;
    my $sth;
    my $table;
    my $id_frag;
    my $id_seq;
    my $seq;

    # FIXME - the following might be slow. However, it seems too complicated to use resultset->search directly.

    $cache_key = $self->cache_key('seq', $source);
    if(!defined($seq = $self->cache->get($cache_key))) {
        $dbh = $self->schema->storage->dbh;
        $query = <<END;
SELECT c.id_seq
FROM   FragToSeqGroup AS a,
       SeqGroup       AS b,
       SeqToGroup     AS c,
       Seq            AS d
WHERE  a.id_frag = ?
AND    b.id = a.id_group
AND    b.type = 'frag'
AND    c.id_group = b.id
AND    d.id = c.id_seq
AND    d.source = '$source'
END
        $sth = $dbh->prepare($query);
        $id_frag = $self->id;
        $sth->execute($id_frag);
        $table = $sth->fetchall_arrayref;
        if(@{$table} == 1) {
            $id_seq = $table->[0]->[0];
            $seq = $self->schema->resultset('Seq')->find({id => $id_seq});
            $self->cache->set($cache_key, $seq);
        }
    }

    return $seq;
};

=head2 _get_mapping

 usage   :
 function:
 args    :
 returns :

=cut

sub _get_mapping {
    my($self) = @_;

    my $cache_key;
    my $mapping;
    my $fist_to_pdb;
    my $pdb_to_fist;
    my $dbh;
    my $query;
    my $sth;
    my $table;
    my $row;
    my $fist;
    my $chain;
    my $resseq;
    my $icode;
    my $res3;
    my $res1;

    $cache_key = $self->cache_key('mapping');
    $mapping = $self->cache->get($cache_key);
    $fist_to_pdb = $mapping->{fist_to_pdb};
    $pdb_to_fist = $mapping->{pdb_to_fist};

    #print "mapping = '$mapping', fist_to_pdb = '$fist_to_pdb', pdb_to_fist = '$pdb_to_fist'\n";

    if(defined($mapping) and defined($fist_to_pdb) and defined($pdb_to_fist)) {
        #print join("\t", '_got_mapping', $self->id, $self), "\n";
    }
    else {
        #print join("\t", '_get_mapping', $self->id, $self), "\n";

        $dbh = $self->schema->storage->dbh;
        $query = 'SELECT fist, chain, resseq, icode, res3, res1 FROM FragResMapping WHERE id_frag = ?';
        $sth = $dbh->prepare($query);
        $sth->execute($self->id);
        $table = $sth->fetchall_arrayref;
        $fist_to_pdb = {};
        $pdb_to_fist = {};
        foreach $row (@{$table}) {
            ($fist, $chain, $resseq, $icode, $res3, $res1) = @{$row};
            $fist_to_pdb->{$fist} = [$chain, $resseq, $icode, $res3, $res1];
            $pdb_to_fist->{$chain}->{$resseq}->{$icode} = $fist;
        }

        $mapping = {fist_to_pdb => $fist_to_pdb, pdb_to_fist => $pdb_to_fist};
        $self->cache->set($cache_key, $mapping);
    }

    return($fist_to_pdb, $pdb_to_fist);
}

sub _get_mapping_v1 {
    my($self) = @_;

    my $fist_to_pdb;
    my $pdb_to_fist;
    my $dbh;
    my $query;
    my $sth;
    my $table;
    my $row;
    my $fist;
    my $chain;
    my $resseq;
    my $icode;

    #print join("\t", '_get_mapping', $self->id, $self), "\n";

    $dbh = $self->schema->storage->dbh;
    $query = 'SELECT fist, chain, resseq, icode FROM FragResMapping WHERE id_frag = ?';
    $sth = $dbh->prepare($query);
    $sth->execute($self->id);
    $table = $sth->fetchall_arrayref;
    $fist_to_pdb = {};
    $pdb_to_fist = {};
    foreach $row (@{$table}) {
        ($fist, $chain, $resseq, $icode) = @{$row};
        $fist_to_pdb->{$fist} = [$chain, $resseq, $icode];
        $pdb_to_fist->{$chain}->{$resseq}->{$icode} = $fist;
    }

    return($fist_to_pdb, $pdb_to_fist);
}

=head2 seq_groups_by_type

 usage   :
 function:
 args    :
 returns :

=cut

sub seq_groups_by_type {
    my($self, $type) = @_;

    my @seq_groups;
    my $frag_to_seq_group;

    @seq_groups = ();
    foreach $frag_to_seq_group ($self->search_related('frag_to_seq_groups')) {
        ($frag_to_seq_group->group->type eq $type) and push(@seq_groups, $frag_to_seq_group->group);
    }

    return @seq_groups;
}

=head2 DEMOLISH

=cut

sub DEMOLISH {
    my($self) = @_;
}

=head2 res_mappings

Type: has_many

Related object: L<Fist::Schema::Result::FragResMapping>

=cut

__PACKAGE__->has_many(
  "res_mappings",
  "Fist::Schema::Result::FragResMapping",
  { "foreign.id_frag" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 type_chem

 usage   :
 function:
 args    :
 returns :

=cut

sub type_chem {
    my($self) = @_;

    my $schema;
    my $dbh;
    my $sth;
    my $table;
    my $id_chem;
    my $type_chem;

    $id_chem = $self->chemical_type;
    if($id_chem eq 'peptide') {
        $type_chem = 'peptide';
    }
    elsif($id_chem eq 'nucleotide') {
        $type_chem = 'nucleotide';
    }
    else {
        $dbh = $self->schema->storage->dbh;
        $sth = $dbh->prepare('SELECT type FROM PdbChem WHERE id_chem = ?');
        $sth->execute($id_chem);
        $table = $sth->fetchall_arrayref;
        $type_chem = (@{$table} > 0) ? $table->[0]->[0] : 'unknown';
    }

    return $type_chem;
}

=head1 ROLES

 with 'Fist::Interface::Frag';

=cut

with 'Fist::Interface::Frag';

__PACKAGE__->meta->make_immutable;
1;
