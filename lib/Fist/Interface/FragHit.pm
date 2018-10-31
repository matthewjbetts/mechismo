package Fist::Interface::FragHit;

use Moose::Role;

=head1 NAME

 Fist::Interface::FragHit

=cut

=head1 ACCESSORS

=cut

=head2 seq1

 usage   :
 function:
 args    :
 returns :

=cut

requires 'seq1';

=head2 start

 usage   :
 function:
 args    :
 returns :

=cut

requires 'start';

=head2 end

 usage   :
 function:
 args    :
 returns :

=cut

requires 'end';

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

=head2 seq2

 usage   :
 function:
 args    :
 returns :

=cut

requires 'seq2';

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

=head2 pcid

 usage   :
 function:
 args    :
 returns :

=cut

requires 'pcid';

=head2 e_value

 usage   :
 function:
 args    :
 returns :

=cut

requires 'e_value';

=head2 aln

 usage   :
 function:
 args    :
 returns :

=cut

requires 'aln';

=head2 id_seq1

 usage   :
 function:
 args    :
 returns :

=cut

sub id_seq1 {
    my($self) = @_;

    return $self->seq1->id;
}

=head2 id_seq2

 usage   :
 function:
 args    :
 returns :

=cut

sub id_seq2 {
    my($self) = @_;

    return $self->seq2->id;
}

=head2 frag

 usage   :
 function:
 args    :
 returns :

=cut

sub frag {
    my($self) = @_;

    return $self->seq2->frag;
}

=head2 id_frag

 usage   :
 function:
 args    :
 returns :

=cut

sub id_frag {
    my($self) = @_;

    return $self->seq2->frag->id;
}

=head1 ROLES

 with 'Fist::Utils::FragHitJSmolSSContacts';

=cut

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
             id_seq1 => $self->id_seq1,
             start   => $self->start,
             end     => $self->end,
             start1  => $self->start1,
             end1    => $self->end1,

             id_seq2 => $self->id_seq2,
             start2  => $self->start2,
             end2    => $self->end2,

             pcid    => $self->pcid,
             e_value => $self->e_value,
             id_aln  => $self->id_aln,
             id_frag => $self->id_frag,
            };

    return $json;
}

=head2 output_tsv

 usage   :
 function:
 args    :
 returns :

=cut

sub output_tsv {
    my($self, $fh) = @_;

    print $fh join("\t", $self->seq1->id, $self->start, $self->end, $self->start1, $self->end1, $self->seq2->id, $self->start2, $self->end2, $self->pcid, $self->e_value, $self->aln->id), "\n";
}

1;
