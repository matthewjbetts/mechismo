use utf8;
package Fist::Schema::Result::Contact;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Fist::Schema::Result::Contact

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

=head1 TABLE: C<Contact>

=cut

__PACKAGE__->table("Contact");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 id_frag_inst1

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 id_frag_inst2

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 crystal

  data_type: 'tinyint'
  default_value: 0
  is_nullable: 0

=head2 n_res1

  data_type: 'smallint'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 n_res2

  data_type: 'smallint'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 n_clash

  data_type: 'smallint'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 n_resres

  data_type: 'smallint'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 homo

  data_type: 'tinyint'
  default_value: 0
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
  "id_frag_inst1",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "id_frag_inst2",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "crystal",
  { data_type => "tinyint", default_value => 0, is_nullable => 0 },
  "n_res1",
  { data_type => "smallint", extra => { unsigned => 1 }, is_nullable => 0 },
  "n_res2",
  { data_type => "smallint", extra => { unsigned => 1 }, is_nullable => 0 },
  "n_clash",
  { data_type => "smallint", extra => { unsigned => 1 }, is_nullable => 0 },
  "n_resres",
  { data_type => "smallint", extra => { unsigned => 1 }, is_nullable => 0 },
  "homo",
  { data_type => "tinyint", default_value => 0, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 frag_inst1

Type: belongs_to

Related object: L<Fist::Schema::Result::FragInst>

=cut

__PACKAGE__->belongs_to(
  "frag_inst1",
  "Fist::Schema::Result::FragInst",
  { id => "id_frag_inst1" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 frag_inst2

Type: belongs_to

Related object: L<Fist::Schema::Result::FragInst>

=cut

__PACKAGE__->belongs_to(
  "frag_inst2",
  "Fist::Schema::Result::FragInst",
  { id => "id_frag_inst2" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

# Created by DBIx::Class::Schema::Loader v0.07033 @ 2012-12-20 13:44:33
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:HCDC/9rqnFD9bKN01Vk1JQ

# You can replace this text with custom code or comments, and it will be preserved on regeneration

use CHI;

=head1 RELATIONS

=cut

=head2 res_contacts

Type: has_many

Related object: L<Fist::Schema::Result::ResContact>

=cut

__PACKAGE__->has_many(
  "res_contacts",
  "Fist::Schema::Result::ResContact",
  {"foreign.id_contact" => "self.id"},
  { cascade_copy => 0, cascade_delete => 0 },
);

sub schema {
    my($self) = @_;

    return $self->result_source->schema;
}

=head1 METHODS

=cut

=head2 type_frag_b

 usage   :
 function:
 args    :
 returns :

=cut

sub type_frag2 {
    my($self, $dbh) = @_;

    my $type;
    my $query;
    my $sth;
    my $table;

    if(!defined($type = $self->_type_frag2)) {
        defined($dbh) or ($dbh = $self->result_source->schema->storage->dbh);
        $query = <<END;
SELECT f.chemical_type
FROM   Contact    AS c,
       FragInst   AS fi,
       Frag       AS f
WHERE  c.id = ?
AND    fi.id = c.id_frag_inst2
AND    f.id = fi.id_frag
END
        $sth = $dbh->prepare($query);
        $sth->execute($self->id);
        $table = $sth->fetchall_arrayref;
        $type = (@{$table} > 0) ? $table->[0]->[0] : undef;
        $self->_type_frag2($type);
    }

    return $type;
}

=head2 _calc_fist_contacts

 usage   :
 function:
 args    :
 returns :

=cut

sub _calc_fist_contacts {
    my($self) = @_;

    my $fist_contacts;
    my $dbh;
    my $query;
    my $sth;
    my $table;
    my $row;
    my $frm1;
    my $frm2;
    my $fist1;
    my $fist2;
    my $res3_1;
    my $res3_2;

    if(!defined($fist_contacts = $self->cache->get($self->cache_key))) {
        $dbh = $self->schema->storage->dbh;

        # have to get FragResMapping separately from ResContact because some
        # fragments do not have a ResMapping (these fragments should be chemicals)

        # FIXME - caching frm1 and frm2 might speed things up
        $query = <<END;
SELECT frm.chain,
       frm.resseq,
       frm.icode,
       frm.fist,
       frm.res3
FROM   Contact AS c,
       FragInst AS fi,
       FragResMapping AS frm
WHERE  c.id = ?
AND    fi.id = c.id_frag_inst1
AND    frm.id_frag = fi.id_frag
END
        $frm1 = _get_frm($dbh->prepare($query), $self->id);
        #print join("\t", 'FRM', $self->id_frag_inst1), "\n";

        $query = <<END;
SELECT frm.chain,
       frm.resseq,
       frm.icode,
       frm.fist,
       frm.res3
FROM   Contact AS c,
       FragInst AS fi,
       FragResMapping AS frm
WHERE  c.id = ?
AND    fi.id = c.id_frag_inst2
AND    frm.id_frag = fi.id_frag
END
        $frm2 = _get_frm($dbh->prepare($query), $self->id);
        #print join("\t", 'FRM', $self->id_frag_inst2), "\n";

        $query = <<END;
SELECT rc.chain1,
       rc.resseq1,
       rc.icode1,

       rc.chain2,
       rc.resseq2,
       rc.icode2,

       rc.bond_type

FROM   Contact        AS c,
       ResContact     AS rc

WHERE  c.id = ?
AND    rc.id_contact = c.id

AND    (
        # ResContacts are stored in both directions so
        # need to avoid counting them twice for intra-contacts
        (c.id_frag_inst2 != c.id_frag_inst1)
        OR (rc.chain2 > rc.chain1)
        OR (rc.resseq2 > rc.resseq1)
        OR (rc.icode2 > rc.icode1)
       )
END
        $sth = $dbh->prepare($query);
        $sth->execute($self->id);
        $table = $sth->fetchall_arrayref;
        $fist_contacts = {n => 0, pos => {}};
        if(defined($frm1)) {
            if(defined($frm2)) {
                foreach $row (@{$table}) {
                    defined($frm1->{$row->[0]}->{$row->[1]}->{$row->[2]}) or next;
                    ($fist1, $res3_1) = @{$frm1->{$row->[0]}->{$row->[1]}->{$row->[2]}};

                    defined($frm2->{$row->[3]}->{$row->[4]}->{$row->[5]}) or next;
                    ($fist2, $res3_2) = @{$frm2->{$row->[3]}->{$row->[4]}->{$row->[5]}};

                    $fist_contacts->{pos}->{$fist1}->{$fist2} = [@{$row}, $res3_1, $res3_2];
                }
            }
            else {
                $fist2 = 1;
                $res3_2 = 'UNK';

                foreach $row (@{$table}) {
                    defined($frm1->{$row->[0]}->{$row->[1]}->{$row->[2]}) or next;
                    ($fist1, $res3_1) = @{$frm1->{$row->[0]}->{$row->[1]}->{$row->[2]}};
                    $fist_contacts->{pos}->{$fist1}->{$fist2} = [@{$row}, $res3_1, $res3_2];
                }
           }
        }
        elsif(defined($frm2)) {
            $fist1 = 1;
            $res3_1 = 'UNK';
            foreach $row (@{$table}) {
                defined($frm2->{$row->[3]}->{$row->[4]}->{$row->[5]}) or next;
                ($fist2, $res3_2) = @{$frm2->{$row->[3]}->{$row->[4]}->{$row->[5]}};
                $fist_contacts->{pos}->{$fist1}->{$fist2} = [@{$row}, $res3_1, $res3_2];
            }
        }
        else {
            $fist1 = 1;
            $res3_1 = 'UNK';
            $fist2 = 1;
            $res3_2 = 'UNK';

            foreach $row (@{$table}) {
                $fist_contacts->{pos}->{$fist1}->{$fist2} = [@{$row}, $res3_1, $res3_2];
            }
        }

        foreach $fist1 (keys %{$fist_contacts->{pos}}) {
            $fist_contacts->{n} += scalar keys %{$fist_contacts->{pos}->{$fist1}};
        }
        $self->cache->set($self->cache_key, $fist_contacts);
   }

    return $fist_contacts;
}

sub _get_frm {
    my($sth, $id) = @_;

    my $table;
    my $frm;
    my $row;

    $sth->execute($id);
    $table = $sth->fetchall_arrayref;
    $frm = undef;
    if(@{$table} > 0) {
        $frm = {};
        foreach $row (@{$table}) {
            $frm->{$row->[0]}->{$row->[1]}->{$row->[2]} = [$row->[3], $row->[4]];
        }
    }

    return $frm;
}

=head2 get_homo

 usage   :
 function:
 args    :
 returns :

=cut

sub get_homo {
    my($self) = @_;

    # only run this once for each contact, then store the results

    my $dbh;
    my $query;
    my $sth;
    my $table;
    my $homo;

    $dbh = $self->schema->storage->dbh;
    $query = <<END;
SELECT  sg.id

FROM    FragInst       AS fi1,
        Frag           AS f1,
        FragToSeqGroup AS f1_to_fg1,
        SeqGroup       AS fg1,
        SeqToGroup     AS s1_to_fg1,
        Seq            AS s1,
        SeqToGroup     AS s1_to_sg,

        SeqGroup       AS sg,

        FragInst       AS fi2,
        Frag           AS f2,
        FragToSeqGroup AS f2_to_fg2,
        SeqGroup       AS fg2,
        SeqToGroup     AS s2_to_fg2,
        Seq            AS s2,
        SeqToGroup     AS s2_to_sg

WHERE   fi1.id             = ?
AND     f1.id              = fi1.id_frag
AND     f1_to_fg1.id_frag  = f1.id
AND     fg1.id             = f1_to_fg1.id_group
AND     fg1.type           = 'frag'
AND     s1_to_fg1.id_group = fg1.id
AND     s1.id              = s1_to_fg1.id_seq
AND     s1.source          = 'fist'
AND     s1_to_sg.id_seq    = s1.id

AND     sg.id              = s1_to_sg.id_group
AND     sg.type            IN ('frag', 'fist lf=0.5 pcid=50.0')

AND     fi2.id             = ?
AND     f2.id              = fi2.id_frag
AND     f2_to_fg2.id_frag  = f2.id
AND     fg2.id             = f2_to_fg2.id_group
AND     fg2.type           = 'frag'
AND     s2_to_fg2.id_group = fg2.id
AND     s2.id              = s2_to_fg2.id_seq
AND     s2.source          = 'fist'
AND     s2_to_sg.id_seq    = s2.id
AND     s2_to_sg.id_group  = sg.id
END
    $sth = $dbh->prepare($query);

    # classify template as homo or hetero dimer
    $sth->execute($self->id_frag_inst1, $self->id_frag_inst2);
    $table = $sth->fetchall_arrayref();
    $homo = (@{$table} > 0) ? 1 : 0;

    return $homo;
}

=head1 ROLES

 with 'Fist::Interface::Contact';

=cut

with 'Fist::Interface::Contact';

__PACKAGE__->meta->make_immutable;
1;
