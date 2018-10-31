use utf8;
package Fist::Schema::Result::FragInst;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Fist::Schema::Result::FragInst

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

=head1 TABLE: C<FragInst>

=cut

__PACKAGE__->table("FragInst");

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

=head2 assembly

  data_type: 'smallint'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 model

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
  "id_frag",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "assembly",
  { data_type => "smallint", extra => { unsigned => 1 }, is_nullable => 0 },
  "model",
  { data_type => "smallint", extra => { unsigned => 1 }, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 contact_id_frag_inst1s

Type: has_many

Related object: L<Fist::Schema::Result::Contact>

=cut

__PACKAGE__->has_many(
  "contact_id_frag_inst1s",
  "Fist::Schema::Result::Contact",
  { "foreign.id_frag_inst1" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 contact_id_frag_inst2s

Type: has_many

Related object: L<Fist::Schema::Result::Contact>

=cut

__PACKAGE__->has_many(
  "contact_id_frag_inst2s",
  "Fist::Schema::Result::Contact",
  { "foreign.id_frag_inst2" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 feature_inst_contact_id_frag_inst1s

Type: has_many

Related object: L<Fist::Schema::Result::FeatureInstContact>

=cut

__PACKAGE__->has_many(
  "feature_inst_contact_id_frag_inst1s",
  "Fist::Schema::Result::FeatureInstContact",
  { "foreign.id_frag_inst1" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 feature_inst_contact_id_frag_inst2s

Type: has_many

Related object: L<Fist::Schema::Result::FeatureInstContact>

=cut

__PACKAGE__->has_many(
  "feature_inst_contact_id_frag_inst2s",
  "Fist::Schema::Result::FeatureInstContact",
  { "foreign.id_frag_inst2" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

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

=head2 tran_id_frag_inst1s

Type: has_many

Related object: L<Fist::Schema::Result::Tran>

=cut

__PACKAGE__->has_many(
  "tran_id_frag_inst1s",
  "Fist::Schema::Result::Tran",
  { "foreign.id_frag_inst1" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 tran_id_frag_inst2s

Type: has_many

Related object: L<Fist::Schema::Result::Tran>

=cut

__PACKAGE__->has_many(
  "tran_id_frag_inst2s",
  "Fist::Schema::Result::Tran",
  { "foreign.id_frag_inst2" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-08-05 15:41:36
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:G+ETX4wUFZi+SkZ5RcKzZw

# You can replace this text with custom code or comments, and it will be preserved on regeneration

=head1 ROLES

 with 'Fist::Interface::FragInst';

=cut

with 'Fist::Interface::FragInst';

=head1 METHODS

=cut

=head2 seq

 usage   :
 function:
 args    :
 returns :

=cut

sub seq {
    my($self, $source, $id_only) = @_;

    my $dbh;
    my $query;
    my $sth;
    my $row;
    my $seq;
    my $seq_cache_key;

    $seq_cache_key = $self->cache_key('seqs', $source);
    if(!defined($seq = $self->cache->get($seq_cache_key))) {
        $dbh = $self->result_source->schema->storage->dbh;
        $query = <<END;
SELECT s.id
FROM   FragInst         AS fi,
       FragToSeqGroup   AS f_to_sg,
       SeqGroup         AS sg,
       SeqToGroup       AS s_to_sg,
       Seq              AS s
WHERE  fi.id = ?
AND    f_to_sg.id_frag = fi.id_frag
AND    sg.id = f_to_sg.id_group
AND    sg.type = 'frag'
AND    s_to_sg.id_group = sg.id
AND    s.id = s_to_sg.id_seq
AND    s.source = ?
END
        $sth = $dbh->prepare($query);
        $sth->execute($self->id, $source);
        if(defined($row = $sth->fetchrow_arrayref)) { # WARNING: assuming only one row
            $seq = $self->result_source->schema->resultset('Seq')->search({id => $row->[0]})->first;
            $sth->finish;
            $self->cache->set($seq_cache_key, $seq);
        }
    }
    $seq = ($id_only and defined($seq)) ? $seq->id : $seq;

    return $seq;
}

sub seq_v01 {
    my($self, $source, $id_only) = @_;

    my $dbh;
    my $query;
    my $sth;
    my $row;
    my $seq;

    $dbh = $self->result_source->schema->storage->dbh;
    $query = <<END;
SELECT s.id
FROM   FragInst         AS fi,
       FragToSeqGroup   AS f_to_sg,
       SeqGroup         AS sg,
       SeqToGroup       AS s_to_sg,
       Seq              AS s
WHERE  fi.id = ?
AND    f_to_sg.id_frag = fi.id_frag
AND    sg.id = f_to_sg.id_group
AND    sg.type = 'frag'
AND    s_to_sg.id_group = sg.id
AND    s.id = s_to_sg.id_seq
AND    s.source = ?
END
    $sth = $dbh->prepare($query);
    $sth->execute($self->id, $source);
    if(defined($row = $sth->fetchrow_arrayref)) { # WARNING: assuming only one row
        if($id_only) {
            $seq = $row->[0];
        }
        else {
            $seq = $self->result_source->schema->resultset('Seq')->search({id => $row->[0]})->first;
        }
        $sth->finish;
    }

    return $seq;
}

=head2 aligned_seq

 usage   :
 function:
 args    :
 returns :

=cut

sub aligned_seq {
    my($self, $source) = @_;

    my $dbh;
    my $query;
    my $sth;
    my $row;
    my $aseq;
    my $aseq_cache_key;

    $aseq_cache_key = $self->cache_key('aseqs', $source);

    if(!defined($aseq = $self->cache->get($aseq_cache_key))) {
        $dbh = $self->result_source->schema->storage->dbh;
        $query = <<END;
SELECT a_to_sg.id_aln,
       s.id
FROM   FragInst         AS fi,
       FragToSeqGroup   AS f_to_sg,
       SeqGroup         AS sg,
       SeqToGroup       AS s_to_sg,
       Seq              AS s,
       AlignmentToGroup AS a_to_sg
WHERE  fi.id = ?
AND    f_to_sg.id_frag = fi.id_frag
AND    sg.id = f_to_sg.id_group
AND    sg.type = 'frag'
AND    s_to_sg.id_group = sg.id
AND    s.id = s_to_sg.id_seq
AND    s.source = ?
AND    a_to_sg.id_group = sg.id
END
        $sth = $dbh->prepare($query);
        $sth->execute($self->id, $source);
        if(defined($row = $sth->fetchrow_arrayref)) { # WARNING: assuming only one row
            $aseq = $self->result_source->schema->resultset('AlignedSeq')->search({id_aln => $row->[0], id_seq => $row->[1]})->first;
            $sth->finish;
            $self->cache->set($aseq_cache_key, $aseq);
        }
    }

    return $aseq;
}

sub aligned_seq_v01 {
    my($self, $source) = @_;

    my $dbh;
    my $query;
    my $sth;
    my $row;
    my $aseq;

    $dbh = $self->result_source->schema->storage->dbh;
    $query = <<END;
SELECT a_to_sg.id_aln,
       s.id
FROM   FragInst         AS fi,
       FragToSeqGroup   AS f_to_sg,
       SeqGroup         AS sg,
       SeqToGroup       AS s_to_sg,
       Seq              AS s,
       AlignmentToGroup AS a_to_sg
WHERE  fi.id = ?
AND    f_to_sg.id_frag = fi.id_frag
AND    sg.id = f_to_sg.id_group
AND    sg.type = 'frag'
AND    s_to_sg.id_group = sg.id
AND    s.id = s_to_sg.id_seq
AND    s.source = ?
AND    a_to_sg.id_group = sg.id
END
    $sth = $dbh->prepare($query);
    $sth->execute($self->id, $source);
    if(defined($row = $sth->fetchrow_arrayref)) { # WARNING: assuming only one row
        $aseq = $self->result_source->schema->resultset('AlignedSeq')->search({id_aln => $row->[0], id_seq => $row->[1]})->first;
        $sth->finish;
    }

    return $aseq;
}

=head2 res_contact_table

 usage   :
 function: gets intra-fragint residues in contact, with sidechain-sidechain etc info.
 args    :
 returns :

=cut

sub res_contact_table {
    my($self) = @_;

    my $dbh;
    my $query;
    my $sth_frm;
    my $sth_rc;
    my $row;
    my $table;
    my $table2;
    my $table_cache_key;
    my $frm;
    my $fist1;
    my $fist2;

    $table_cache_key = $self->cache_key('res_contact_table', $self->frag->cache_key);
    if(!defined($table = $self->cache->get($table_cache_key))) {
        $dbh = $self->result_source->schema->storage->dbh;

        $query = <<END;
SELECT frm.chain,
       frm.resseq,
       frm.icode,
       frm.fist
FROM   FragResMapping AS frm
WHERE  frm.id_frag = ?
END
        $sth_frm = $dbh->prepare($query);

        $query = <<END;
SELECT rc.chain1,
       rc.resseq1,
       rc.icode1,

       rc.chain2,
       rc.resseq2,
       rc.icode2,

       rc.sm,
       rc.ms,
       rc.mm,
       rc.ss,

       rc.ss_salt,
       rc.ss_hbond,
       rc.ss_end,

       rc.ss_unmod_salt,
       rc.ss_unmod_hbond,
       rc.ss_unmod_end

FROM   FragInst   AS fi,
       Contact    AS c,
       ResContact AS rc

WHERE  fi.id_frag = ?
AND    fi.assembly = 0
AND    fi.model = 0
AND    c.id_frag_inst1 = fi.id
AND    c.id_frag_inst2 = fi.id
AND    rc.id_contact = c.id
END
        $sth_rc = $dbh->prepare($query);

        $sth_frm->execute($self->id_frag);
        $table2 = $sth_frm->fetchall_arrayref;
        $frm = {};
        foreach $row (@{$table2}) {
            $frm->{$row->[0]}->{$row->[1]}->{$row->[2]} = $row->[3];
        }

        $sth_rc->execute($self->id_frag);

        $table2 = $sth_rc->fetchall_arrayref;
        $table = [];
        foreach $row (@{$table2}) {
            # intra-contact so can use same FragResMapping info for both sides
            $fist1 = $frm->{$row->[0]}->{$row->[1]}->{$row->[2]};
            defined($fist1) or next;

            $fist2 = $frm->{$row->[3]}->{$row->[4]}->{$row->[5]};
            defined($fist2) or next;

            push @{$table}, {
                             fist1          => $fist1,
                             fist2          => $fist2,

                             chain1         => $row->[0],
                             resseq1        => $row->[1],
                             icode1         => $row->[2],

                             chain2         => $row->[3],
                             resseq2        => $row->[4],
                             icode2         => $row->[5],

                             sm             => $row->[6],
                             ms             => $row->[7],
                             mm             => $row->[8],
                             ss             => $row->[9],

                             ss_salt        => $row->[11],
                             ss_hbond       => $row->[12],
                             ss_end         => $row->[13],

                             ss_unmod_salt  => $row->[14],
                             ss_unmod_hbond => $row->[15],
                             ss_unmod_end   => $row->[16],
                            };

            # only stored in one direction in the db, so add the other direction here
            push @{$table}, {
                             fist1          => $fist2,
                             fist2          => $fist1,

                             chain1         => $row->[3],
                             resseq1        => $row->[4],
                             icode1         => $row->[5],

                             chain2         => $row->[0],
                             resseq2        => $row->[1],
                             icode2         => $row->[2],

                             ms             => $row->[7],
                             sm             => $row->[6],
                             mm             => $row->[8],
                             ss             => $row->[9],

                             ss_salt        => $row->[11],
                             ss_hbond       => $row->[12],
                             ss_end         => $row->[13],

                             ss_unmod_salt  => $row->[14],
                             ss_unmod_hbond => $row->[15],
                             ss_unmod_end   => $row->[16],
                            }
        }

        $self->cache->set($table_cache_key, $table);
    }

    return $table;
}

=head2 res_contact_table_list

 usage   :
 function: gets intra-fragint residues in contact, with sidechain-sidechain etc info

           $table->{rows}   # rows of data
           $table->{fields} # keys for rows, eg. $table->{fields}->{pos_a1} gives the column number of 'pos_a1' info in a row
           $table->{resres} # row numbers for a particular residue-residue contact, keyed by query sequence positions, eg $table->{resres}->{100}->{120};
 args    :
 returns :

=cut

sub res_contact_table_list {
    my($self) = @_;

    my $dbh;
    my $query;
    my $sth;
    my $row;
    my $table;
    my $table2;
    my $table_cache_key;
    my $fist1;
    my $fist2;
    my $i;

    $table_cache_key = $self->cache_key('res_contact_table', $self->frag->cache_key);
    if(!defined($table = $self->cache->get($table_cache_key))) {
        $dbh = $self->result_source->schema->storage->dbh;
        $query = <<END;
SELECT frm1.fist,
       frm2.fist,

       frm1.chain,
       frm1.resseq,
       frm1.icode,

       frm2.chain,
       frm2.resseq,
       frm2.icode,

       rc.sm,
       rc.ms,
       rc.mm,
       rc.ss,

       rc.ss_salt,
       rc.ss_hbond,
       rc.ss_end,

       rc.ss_unmod_salt,
       rc.ss_unmod_hbond,
       rc.ss_unmod_end

FROM   FragInst       AS fi,
       Contact        AS c,
       ResContact     AS rc,
       FragResMapping AS frm1,
       FragResMapping AS frm2

WHERE  fi.id_frag = ?
AND    fi.assembly = 0
AND    fi.model = 0
AND    c.id_frag_inst1 = fi.id
AND    c.id_frag_inst2 = fi.id
AND    rc.id_contact = c.id

AND    frm1.id_frag = fi.id_frag
AND    frm1.chain = rc.chain1
AND    frm1.resseq = rc.resseq1
AND    frm1.icode = rc.icode1

AND    frm2.id_frag = fi.id_frag
AND    frm2.chain = rc.chain2
AND    frm2.resseq = rc.resseq2
AND    frm2.icode = rc.icode2

AND    frm2.fist != frm1.fist

END

        $sth = $dbh->prepare($query);
        $sth->execute($self->frag->id);

        #print __FILE__, ' res_contact_table, id_frag = ', $self->frag->id, "\n";

        $table = {
                  fields => {
                             'fist1'          => 0,
                             'fist2'          => 1,

                             'chain1'         => 2,
                             'resseq1'        => 3,
                             'icode1'         => 4,

                             'chain2'         => 5,
                             'resseq2'        => 6,
                             'icode2'         => 7,

                             'sm'             => 8,
                             'ms'             => 9,
                             'mm'             => 10,
                             'ss'             => 11,

                             'ss_salt'        => 12,
                             'ss_hbond'       => 13,
                             'ss_end'         => 14,

                             'ss_unmod_salt'  => 15,
                             'ss_unmod_hbond' => 16,
                             'ss_unmod_end'   => 17,
                            },
                  rows => [],
                  resres => {},
                 };

        $table2 = $sth->fetchall_arrayref;
        $i = 0;
        foreach $row (@{$table2}) {
            $fist1 = $row->[0];
            $fist2 = $row->[1];

            $table->{resres}->{$fist1}->{$fist2} = $i;
            push @{$table->{rows}}, [@{$row}];
            ++$i;

            # only stored in one direction in the db, so add the other direction here
            $table->{resres}->{$fist2}->{$fist1} = $i;
            push @{$table->{rows}}, [
                                     $row->[1],
                                     $row->[0],
                                     @{$row}[5..7],
                                     @{$row}[2..4],

                                     $row->[9], # sm in reverse direction = ms in selected direction
                                     $row->[8], # ms in reverse direction = sm in selected direction

                                     @{$row}[10..17],
                                    ];
            ++$i;

        }

        $self->cache->set($table_cache_key, $table);
    }

    return $table;
}


__PACKAGE__->meta->make_immutable;
1;
