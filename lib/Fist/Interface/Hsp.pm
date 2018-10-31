package Fist::Interface::Hsp;

use Moose::Role;
use CHI;

=head1 NAME

 Fist::Interface::Hsp

=cut

=head1 ACCESSORS

=cut

=head2 id

 usage   :
 function:
 args    :
 returns :

=cut

requires 'id';

=head2 id_seq1

 usage   :
 function:
 args    :
 returns :

=cut

requires 'id_seq1';

=head2 seq1

 usage   :
 function:
 args    :
 returns :

=cut

requires 'seq1';

=head2 id_seq2

 usage   :
 function:
 args    :
 returns :

=cut

requires 'id_seq2';

=head2 seq2

 usage   :
 function:
 args    :
 returns :

=cut

requires 'seq2';

=head2 pcid

 usage   :
 function:
 args    :
 returns :

=cut

requires 'pcid';

=head2 a_len

 usage   :
 function:
 args    :
 returns :

=cut

requires 'a_len';

=head2 n_gaps

 usage   :
 function:
 args    :
 returns :

=cut

requires 'n_gaps';

=head2 start1

 usage   :
 function:
 args    :
 returns :

=cut

requires 'start1';

=head2 end1

 usage   :
 function:
 args    :
 returns :

=cut

requires 'end1';

=head2 start2

 usage   :
 function:
 args    :
 returns :

=cut

requires 'start2';

=head2 end2

 usage   :
 function:
 args    :
 returns :

=cut

requires 'end2';

=head2 e_value

 usage   :
 function:
 args    :
 returns :

=cut

requires 'e_value';

=head2 score

 usage   :
 function:
 args    :
 returns :

=cut

requires 'score';

=head2 aln

 usage   :
 function:
 args    :
 returns :

=cut

requires 'aln';

=head1 ROLES

 with 'Fist::Utils::UniqueIdentifier';
 with 'Fist::Utils::Cache';
 with 'Fist::Utils::FragHitJSmolSSContacts';

=cut

with 'Fist::Utils::UniqueIdentifier';
with 'Fist::Utils::Cache';
with 'Fist::Utils::FragHitJSmolSSContacts';

=head1 METHODS

=cut

=head2 TO_JSON

 usage   :
 function:
 args    :
 returns :

=cut

sub TO_JSON {
    my($self) = @_;

    my $json;

    $json = {
             id      => $self->id,

             id_seq1 => $self->id_seq1,
             start1  => $self->start1,
             end1    => $self->end1,

             id_seq2 => $self->id_seq2,
             start2  => $self->start2,
             end2    => $self->end2,

             pcid    => $self->pcid,
             e_value => $self->e_value,
             aln     => $self->aln->TO_JSON,

             a_len   => $self->a_len,
             n_gaps  => $self->n_gaps,
             score   => $self->score,
            };

    return $json;
}

=head2 string

 usage   :
 function:
 args    :
 returns :

=cut

sub string {
    my($self, $len1, $len2) = @_;

    my $cache_key;
    my $id_seq1;
    my $id_seq2;
    my $aln;
    my $aseq1;
    my $aseq2;
    my $str;

    $cache_key = $self->cache_key('string');
    if(!defined($str = $self->cache->get($cache_key))) {
        $id_seq1 = $self->id_seq1;
        $id_seq2 = $self->id_seq2;
        $aln = $self->aln;
        $aseq1 = $aln->aseq($id_seq1);
        $aseq2 = $aln->aseq($id_seq2);
        defined($len1) or ($len1 = $self->seq1->len);
        defined($len2) or ($len1 = $self->seq2->len);

        $str = join(
                    "\t",
                    $self->id,
                    $self->pcid,
                    $self->score,
                    $self->e_value,
                    $id_seq1,
                    $id_seq2,

                    $len1,
                    $self->start1,
                    $self->end1,
                    $aseq1->edit_str,

                    $len2,
                    $self->start2,
                    $self->end2,
                    $aseq2->edit_str,
                   );
        $self->cache->set($cache_key, $str);
    }

    return $str;
}

=head2 string_reverse

 usage   :
 function:
 args    :
 returns :

=cut

sub string_reverse {
    my($self, $len1, $len2) = @_;

    my $cache_key;
    my $id_seq1;
    my $id_seq2;
    my $aln;
    my $aseq1;
    my $aseq2;
    my $str;

    $cache_key = $self->cache_key('string_reverse');
    if(!defined($str = $self->cache->get($cache_key))) {
        $id_seq1 = $self->id_seq1;
        $id_seq2 = $self->id_seq2;
        $aln = $self->aln;
        $aseq1 = $aln->aseq($id_seq1);
        $aseq2 = $aln->aseq($id_seq2);
        defined($len1) or ($len1 = $self->seq1->len);
        defined($len2) or ($len1 = $self->seq2->len);

        $str = join(
                    "\t",
                    $self->id,
                    $self->pcid,
                    $self->score,
                    $self->e_value,
                    $id_seq2,
                    $id_seq1,

                    $len2,
                    $self->start2,
                    $self->end2,
                    $aseq2->edit_str,

                    $len1,
                    $self->start1,
                    $self->end1,
                    $aseq1->edit_str,
                   );
        $self->cache->set($cache_key, $str);
    }

    return $str;
}

=head2 output_tsv

 usage   :
 function:
 args    :
 returns :

=cut

sub output_tsv {
    my($self, $fh) = @_;

    print $fh join("\t", $self->id, $self->id_seq1, $self->id_seq2, $self->pcid, $self->a_len, $self->n_gaps, $self->start1, $self->end1, $self->start2, $self->end2, $self->e_value, $self->score, $self->aln->id), "\n";
}

1;
