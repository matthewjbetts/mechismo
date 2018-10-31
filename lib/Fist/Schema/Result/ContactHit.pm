use utf8;
package Fist::Schema::Result::ContactHit;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Fist::Schema::Result::ContactHit

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

__PACKAGE__->load_components('InflateColumn::DateTime');

=head1 TABLE: C<ContactHit>

=cut

__PACKAGE__->table("ContactHit");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 type

  data_type: 'varchar'
  default_value: 'UNK'
  is_nullable: 0
  size: 6

=head2 id_seq_a1

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 start_a1

  data_type: 'smallint'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 end_a1

  data_type: 'smallint'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 id_seq_b1

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 start_b1

  data_type: 'smallint'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 end_b1

  data_type: 'smallint'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 id_seq_a2

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 start_a2

  data_type: 'smallint'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 end_a2

  data_type: 'smallint'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 id_seq_b2

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 start_b2

  data_type: 'smallint'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 end_b2

  data_type: 'smallint'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 id_contact

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 n_res_a1

  data_type: 'smallint'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 n_res_b1

  data_type: 'smallint'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 n_resres_a1b1

  data_type: 'smallint'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 pcid_a

  data_type: 'float'
  is_nullable: 0

=head2 e_value_a

  data_type: 'double precision'
  is_nullable: 0

=head2 pcid_b

  data_type: 'float'
  is_nullable: 0

=head2 e_value_b

  data_type: 'double precision'
  is_nullable: 0

=head2 chr

  data_type: 'blob'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "id_seq_a1",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
  "type",
  {
    data_type => "varchar",
    default_value => "none",
    is_nullable => 0,
    size => 6,
  },
  "start_a1",
  { data_type => "smallint", extra => { unsigned => 1 }, is_nullable => 0 },
  "end_a1",
  { data_type => "smallint", extra => { unsigned => 1 }, is_nullable => 0 },
  "id_seq_b1",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
  "start_b1",
  { data_type => "smallint", extra => { unsigned => 1 }, is_nullable => 0 },
  "end_b1",
  { data_type => "smallint", extra => { unsigned => 1 }, is_nullable => 0 },
  "id_seq_a2",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
  "start_a2",
  { data_type => "smallint", extra => { unsigned => 1 }, is_nullable => 0 },
  "end_a2",
  { data_type => "smallint", extra => { unsigned => 1 }, is_nullable => 0 },
  "id_seq_b2",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
  "start_b2",
  { data_type => "smallint", extra => { unsigned => 1 }, is_nullable => 0 },
  "end_b2",
  { data_type => "smallint", extra => { unsigned => 1 }, is_nullable => 0 },
  "id_contact",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
  "n_res_a1",
  { data_type => "smallint", extra => { unsigned => 1 }, is_nullable => 0 },
  "n_res_b1",
  { data_type => "smallint", extra => { unsigned => 1 }, is_nullable => 0 },
  "n_resres_a1b1",
  { data_type => "smallint", extra => { unsigned => 1 }, is_nullable => 0 },
  "pcid_a",
  { data_type => "float", is_nullable => 0 },
  "e_value_a",
  { data_type => "double precision", is_nullable => 0 },
  "pcid_b",
  { data_type => "float", is_nullable => 0 },
  "e_value_b",
  { data_type => "double precision", is_nullable => 0 },
  "chr",
  { data_type => "blob", accessor => '_chr'},
);

sub chr {
    my($self) = shift;

    my $dbh;
    my $sth;
    my $table;
    my $chr;

    # FIXME - only works for get, not set

    # doing this because __PACKAGE__->compresscolumns returned undef...
    # ... looks like it used zlib rather than mysql's UNCOMPRESS?

    $dbh = $self->result_source->schema->storage->dbh;
    $sth = $dbh->prepare('SELECT UNCOMPRESS(chr) FROM ContactHit WHERE id = ?');
    $sth->execute($self->id);
    $table = $sth->fetchall_arrayref;
    $chr = $table->[0]->[0];

    return $chr;
}

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2012-12-20 13:44:33
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:4yJZSDUGoEvIzPRyXP0qAA

use Fist::NonDB::Hsp;

=head2 seq_a1

Type: belongs_to

Related object: L<Fist::Schema::Result::Seq>

=cut

__PACKAGE__->belongs_to(
  "seq_a1",
  "Fist::Schema::Result::Seq",
  { id => "id_seq_a1" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 seq_b1

Type: belongs_to

Related object: L<Fist::Schema::Result::Seq>

=cut

__PACKAGE__->belongs_to(
  "seq_b1",
  "Fist::Schema::Result::Seq",
  { id => "id_seq_b1" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 seq_a2

Type: belongs_to

Related object: L<Fist::Schema::Result::Seq>

=cut

__PACKAGE__->belongs_to(
  "seq_a2",
  "Fist::Schema::Result::Seq",
  { id => "id_seq_a2" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 seq_b2

Type: belongs_to

Related object: L<Fist::Schema::Result::Seq>

=cut

__PACKAGE__->belongs_to(
  "seq_b2",
  "Fist::Schema::Result::Seq",
  { id => "id_seq_b2" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

sub get_seq {
    my($self, $id_seq) = @_;

    my $cache_key;
    my $seq;

    $cache_key = join ':', 'Seq', $id_seq;
    if(!defined($seq = $self->cache->get($cache_key))) {
        $seq = $self->result_source->schema->resultset('Seq')->find($id_seq);
        $self->cache->set($cache_key, $seq);
    }

    return $seq;
}

=head2 contact

Type: belongs_to

Related object: L<Fist::Schema::Result::Contact>

=cut

__PACKAGE__->belongs_to(
  "contact",
  "Fist::Schema::Result::Contact",
  { id => "id_contact" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

sub _chem_type {
    my($sth, $id) = @_;

    my $table;
    my $chem_type;

    $sth->execute($id);
    $table = $sth->fetchall_arrayref;
    $chem_type = (@{$table} > 0) ? $table->[0]->[0] : undef;

    return $chem_type;
}

=head2 n_resres_a1b1

=cut

sub n_resres_a1b1 {
    my($self) = @_;

    return $self->n_resres_a1_b1;
}

=head2 contact_hit_interprets

Type: has_many

Related object: L<Fist::Schema::Result::ContactHitInterprets>

=cut


__PACKAGE__->has_many(
  "contact_hit_interprets",
  "Fist::Schema::Result::ContactHitInterprets",
  { "foreign.id_contact_hit" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head1 METHODS

=cut

=head2 get_hsp

=cut

sub get_hsp {
    my($self, $id_seq1, $start1, $end1, $id_seq2, $start2, $end2, $seq1, $seq2, $e_value, $pcid) = @_;

    my $schema;
    my $cache_key;
    my $hsp;
    my $dbh;
    my $sth;
    my $query;
    my $table;
    my $id_aln;
    my $e_value2;
    my $aln;

    ($id_seq1 and $id_seq2) or return(undef);

    $schema = $self->result_source->schema;
    $cache_key = join ':', 'HSP', $id_seq1, $start1, $end1, $id_seq2, $start2, $end2;
    if(defined($hsp = $self->cache->get($cache_key))) {
        $hsp = $schema->thaw($hsp);
    }
    else {
        if($id_seq1) {
            if($id_seq2) {
                $hsp = $schema->resultset('Hsp')->find({id_seq1 => $id_seq1, start1 => $start1, end1 => $end1, id_seq2 => $id_seq2, start2 => $start2, end2 => $end2});
                if(!defined($hsp)) {
                    $dbh = $schema->storage->dbh;

                    # get fake hsp via frag alignment group (SIFTS)
                    $query = <<END;
SELECT a_to_g.id_aln,
       0.0
FROM   SeqToGroup       AS s1_to_g,
       SeqToGroup       AS s2_to_g,
       SeqGroup         AS g,
       AlignmentToGroup AS a_to_g
WHERE  s1_to_g.id_seq = ?
AND    s2_to_g.id_seq = ?
AND    s2_to_g.id_group = s1_to_g.id_group
AND    g.id = s1_to_g.id_group
AND    g.type = 'frag'
AND    a_to_g.id_group = g.id
END
                    $sth = $dbh->prepare($query);
                    $sth->execute($id_seq1, $id_seq2);
                    $table = $sth->fetchall_arrayref;

                    if(@{$table} == 0) {
                        # get fake hsp via pfam alignment group
                        $dbh = $schema->storage->dbh;
                        $query = <<END;
SELECT a_to_g.id_aln,
       GREATEST(fi1.e_value, fi2.e_value)

FROM   Seq              AS s1,
       FeatureInst      AS fi1,
       Feature          AS f,
       FeatureInst      AS fi2,
       Seq              AS s2,
       SeqGroup         AS g,
       AlignmentToGroup AS a_to_g

WHERE  s1.id = ?
AND    fi1.id_seq = s1.id
AND    fi1.start_seq = ?
AND    fi1.end_seq = ?
AND    f.id = fi1.id_feature
AND    f.source = 'pfam'
AND    fi2.id_feature = f.id
AND    fi2.id_seq = ?
AND    fi2.start_seq = ?
AND    fi2.end_seq = ?
AND    s2.id = fi2.id_seq
AND    g.type = 'pfam'
AND    g.ac = f.ac_src
AND    a_to_g.id_group = g.id
END
                        $sth = $dbh->prepare($query);
                        $sth->execute($id_seq1, $start1, $end1, $id_seq2, $start2, $end2);
                        $table = $sth->fetchall_arrayref;
                    }

                    if(@{$table} > 0) {
                        ($id_aln, $e_value2) = @{$table->[0]};
                        $aln = $schema->resultset('Alignment')->find({id => $id_aln});
                        defined($seq1) or ($seq1 = $schema->resultset('Seq')->find({id => $id_seq1}));
                        defined($seq2) or ($seq2 = $schema->resultset('Seq')->find({id => $id_seq2}));

                        #  if pcid is missing or zero, calculate it from the two aligned sequences
                        (defined($pcid) and ($pcid > 0.000001)) or ($pcid = $aln->pcid($id_seq1, $id_seq2, $seq1, $seq2));

                        $hsp = Fist::NonDB::Hsp->new(
                                                     seq1    => $seq1,
                                                     seq2    => $seq2,
                                                     pcid    => $pcid,
                                                     a_len   => $aln->len,
                                                     n_gaps  => 0,   # FIXME - calculate from the two aligned sequences
                                                     start1  => $start1,
                                                     end1    => $end1,
                                                     start2  => $start2,
                                                     end2    => $end2,
                                                     score   => 0.0, # FIXME - calculate from the two aligned sequences
                                                     e_value => $e_value2,
                                                     aln     => $aln,
                                                    );
                    }
                }
            }
            else {
                # make a fake HSP without seq2
                defined($seq1) or ($seq1 = $schema->resultset('Seq')->find({id => $id_seq1}));
                $hsp = Fist::NonDB::Hsp->new(
                                             seq1    => $seq1,
                                             seq2    => undef,
                                             pcid    => 100.0,
                                             a_len   => $seq1->len,
                                             n_gaps  => 0,
                                             start1  => 1,
                                             end1    => $seq1->len,
                                             start2  => 0,
                                             end2    => 0,
                                             score   => 0.0,
                                             e_value => 0.0,
                                             aln     => undef,
                                            );
            }
        }
        elsif($id_seq2) {
            # make a fake HSP without seq1
            defined($seq2) or ($seq2 = $schema->resultset('Seq')->find({id => $id_seq2}));
            $hsp = Fist::NonDB::Hsp->new(
                                         seq1    => undef,
                                         seq2    => $seq2,
                                         pcid    => 100.0,
                                         a_len   => $seq2->len,
                                         n_gaps  => 0,
                                         start1  => 0,
                                         end1    => 0,
                                         start2  => 1,
                                         end2    => $seq2->len,
                                         score   => 0.0,
                                         e_value => 0.0,
                                         aln     => undef,
                                        );
        }
        defined($hsp) and $self->cache->set($cache_key, $schema->freeze($hsp));
    }

    return $hsp;
}

=head2 hsp_a

=cut

has 'hsp_a' => (is => 'rw', isa => 'Any');

around 'hsp_a' => sub {
    my($orig, $self, $hsp_a, $seq_a1, $seq_a2) = @_;

    if(defined($hsp_a)) {
        $hsp_a = $self->$orig($hsp_a);
    }
    else {
        if(!defined($hsp_a = $self->$orig)) {
            $hsp_a = $self->get_hsp($self->id_seq_a1, $self->start_a1, $self->end_a1, $self->id_seq_a2, $self->start_a2, $self->end_a2, $seq_a1, $seq_a2, $self->e_value_a, $self->pcid_a);
            $self->$orig($hsp_a);
        }
    }

    return $hsp_a;
};

=head2 hsp_b

=cut

has 'hsp_b' => (is => 'rw', isa => 'Any');

around 'hsp_b' => sub {
    my($orig, $self, $hsp_b, $seq_b1, $seq_b2) = @_;

    if(defined($hsp_b)) {
        $hsp_b = $self->$orig($hsp_b);
    }
    else {
        if(!defined($hsp_b = $self->$orig)) {
            $hsp_b = $self->get_hsp($self->id_seq_b1, $self->start_b1, $self->end_b1, $self->id_seq_b2, $self->start_b2, $self->end_b2, $seq_b1, $seq_b2, $self->e_value_b, $self->pcid_b);
            $self->$orig($hsp_b);
        }
    }

    return $hsp_b;
};

=head2 hsp_query

=cut

has 'hsp_query' => (is => 'rw', isa => 'Any');
has 'hsp_query_searched' => (is => 'rw', isa => 'Bool', default => 0); # a flag since there may be no hsp_query even though it has been searched for before

around 'hsp_query' => sub {
    my($orig, $self, $hsp_query) = @_;

    if(defined($hsp_query)) {
        $hsp_query = $self->$orig($hsp_query);
        $self->hsp_query_searched(1);
    }
    else {
        if(!defined($hsp_query = $self->$orig)) {
            $hsp_query = $self->result_source->schema->resultset('Hsp')->search({id_seq1 => $self->id_seq_a1, id_seq2 => $self->id_seq_b1}, {order_by => {-asc => 'e_value'}, rows => 1})->first;
            $self->hsp_query_searched(1);
            $self->$orig($hsp_query);
        }
    }

    return $hsp_query;
};

=head2 hsp_template

=cut

has 'hsp_template' => (is => 'rw', isa => 'Any');
has 'hsp_template_searched' => (is => 'rw', isa => 'Bool', default => 0); # a flag since there may be no hsp_template even though it has been searched for before

around 'hsp_template' => sub {
    my($orig, $self, $hsp_template) = @_;

    if(defined($hsp_template)) {
        $hsp_template = $self->$orig($hsp_template);
        $self->hsp_template_searched(1);
    }
    else {
        if(!defined($hsp_template = $self->$orig) and !$self->hsp_template_searched) {
            $hsp_template = $self->result_source->schema->resultset('Hsp')->search({id_seq1 => $self->id_seq_a2, id_seq2 => $self->id_seq_b2}, {order_by => {-asc => 'e_value'}, rows => 1})->first;
            $self->hsp_template_searched(1);
            $self->$orig($hsp_template);
        }
    }

    return $hsp_template;
};


=head2 map_sites

 usage   :
 function:
 args    :
 returns :

=cut

sub map_sites {
    my($self, $dbh, $json, $type_chem, $id_chem, $mat_pp, $mat_conf, $results_type, $site_info, $seq_a1, $seq_b1) = @_;

    my $id_ch;
    my $type_ch;
    my $homo;
    my $id_seq_a1;
    my $id_seq_b1;
    my $id_frag_inst_a2;
    my $id_frag_inst_b2;
    my $contact;
    my $crystal;
    my $id_aln_a;
    my $id_aln_b;
    my $hsp_a;
    my $hsp_b;
    my $res_contacts;
    my $row;
    my $pos_a1;
    my $pos_a2;
    my $pos_b1;
    my $pos_b2;
    my $n_ss;
    my $site;
    my $res;
    my $res2;
    my $intra_charge;
    my $inter_charge;
    my $res_b1;
    my $res2_b1;
    my $delta;
    my $posns_a1;
    my $ids_alns;

    $type_ch = $self->type;

    # inter contacts
    $posns_a1 = [sort {$a <=> $b} keys %{$site_info->{sites}}];
    $res_contacts = $self->res_contact_table_list('ss_unmod_only', $posns_a1);

    #print join("\t", 'MAP_SITES', $self->id, $type_ch, $type_chem, $id_chem, scalar @{$res_contacts->{rows}}, scalar keys %{$site_info->{sites}}), "\n";

    if(@{$res_contacts->{rows}} > 0) {
        $id_seq_a1 = $self->id_seq_a1; # quicker to copy id_seq_a1 than to use the accessor each time
        $id_seq_b1 = $self->id_seq_b1;
        $id_ch = $self->id;
        $ids_alns = {};
        defined($hsp_a = $self->hsp_a(undef, $seq_a1, undef)) and $json->{results}->{$results_type}->{counts}->{alignments}->{$hsp_a->aln->id}++;
        ($id_seq_b1 != 0) and defined($hsp_b = $self->hsp_b(undef, $seq_b1, undef)) and $json->{results}->{$results_type}->{counts}->{alignments}->{$hsp_b->aln->id}++;
        foreach $pos_a1 (keys %{$site_info->{sites}}) {
            $n_ss = 0;
            foreach $pos_b1 (keys %{$res_contacts->{a1_to_b1}->{$pos_a1}}) {
                $row = $res_contacts->{rows}->[$res_contacts->{a1_to_b1}->{$pos_a1}->{$pos_b1}];
                $n_ss++;

                # record a1 sites that are in the interface and store along with contact_hit
                $site_info->{ch_to_interface_sites}->{$id_ch}->{$pos_a1}++;
                foreach $site (@{$site_info->{sites}->{$pos_a1}->{sites}}) {
                    if(!defined($site->{$type_ch}->{$type_chem}->{$id_chem}->{$id_ch})) {
                        $site->{$type_ch}->{$type_chem}->{$id_chem}->{$id_ch} = {
                                                                                 ie       => 0,         # ie = interprets_delta
                                                                                 ie_class => 'neutral', #
                                                                                 sswitch  => 0,         # sswitch = phos switch score
                                                                                 rc       => [],        # rc = residue contacts
                                                                                };
                    }

                    $res = $site->{res};
                    $res2 = $site->{res2};

                    # if this is a homodimer, then the site may be pointing at itself
                    if(($id_chem eq $id_seq_a1) and ($pos_b1 == $pos_a1)) {
                        $res_b1 = $res;
                        $res2_b1 = $res2;
                    }
                    elsif($type_ch =~ /^PPI/) {
                        $res_b1 = $row->[$res_contacts->{fields}->{res_b1}];
                        $res2_b1 = $res_b1;
                    }
                    else {
                        $res_b1 = $type_chem;
                        $res2_b1 = $type_chem;
                    }

                    #printf "ITPS\t%d\t%d\t%s%d%s\t%s%d%s\t%f\n", $id_seq_a1, $id_chem, $res, $pos_a1, $res2, $res_b1, $pos_b1, $res2_b1, $mat_pp->delta($res, $res_b1, $res2, $res2_b1);

                    if($res2 ne '') {
                        $delta = $mat_pp->delta($res_b1, $res, $res2_b1, $res2); # now in the same order as for mat_prot_chem_class
                        #print "'", join("'\t'", 'DELTA', $id_ch, $type_ch, $res_b1, $res, $res2_b1, $res2, defined($delta) ? $delta : 'undef'), "'\n";
                        #defined($delta) or ($delta = 0);

                        defined($delta) and ($site->{$type_ch}->{$type_chem}->{$id_chem}->{$id_ch}->{ie} += $delta);
                    }
                    else {
                        $delta = 0;
                    }

                    push @{$site->{$type_ch}->{$type_chem}->{$id_chem}->{$id_ch}->{rc}}, {
                                                                                          pos_a1    => $pos_a1,
                                                                                          res_a1    => $row->[$res_contacts->{fields}->{res_a1}],
                                                                                          delta     => $delta,

                                                                                          pos_a2    => $row->[$res_contacts->{fields}->{pos_a2}],
                                                                                          res_a2    => $row->[$res_contacts->{fields}->{res_a2}],
                                                                                          chain_a2  => $row->[$res_contacts->{fields}->{chain_a2}],
                                                                                          resseq_a2 => $row->[$res_contacts->{fields}->{resseq_a2}],
                                                                                          icode_a2  => $row->[$res_contacts->{fields}->{icode_a2}],

                                                                                          pos_b1    => $pos_b1,
                                                                                          res_b1    => $row->[$res_contacts->{fields}->{res_b1}],

                                                                                          pos_b2    => $row->[$res_contacts->{fields}->{pos_b2}],
                                                                                          res_b2    => $row->[$res_contacts->{fields}->{res_b2}],
                                                                                          chain_b2  => $row->[$res_contacts->{fields}->{chain_b2}],
                                                                                          resseq_b2 => $row->[$res_contacts->{fields}->{resseq_b2}],
                                                                                          icode_b2  => $row->[$res_contacts->{fields}->{icode_b2}],

                                                                                          res3_a2   => $row->[$res_contacts->{fields}->{res3_a2}],
                                                                                          res3_b2   => $row->[$res_contacts->{fields}->{res3_b2}],
                                                                                         };
                }
            }

            if($n_ss > 0) {
                # get the class of the interaction effect
                foreach $site (@{$site_info->{sites}->{$pos_a1}->{sites}}) {
                    $site->{$type_ch}->{$type_chem}->{$id_chem}->{$id_ch}->{ie_class} = $mat_conf->ie_class($site->{$type_ch}->{$type_chem}->{$id_chem}->{$id_ch}->{ie});
                }
            }
        }
    }
}

=head1 ROLES

 with 'Fist::Interface::ContactHit';

=cut

with 'Fist::Interface::ContactHit';

__PACKAGE__->meta->make_immutable;
1;
