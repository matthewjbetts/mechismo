package Fist::Interface::Seqs;

use Moose::Role;

=head1 NAME

 Fist::Interface::Seqs

=cut

=head1 ACCESSORS

=cut

=head2 seqs

 usage   : @seqs = $self->seqs();
 function: get all sequences of this object
 args    : none
 returns : a list of Fist::Interface::Seq objects

=cut

requires 'seqs';

=head2 tempdir

 usage   : used internally
 function: get/set temporary directory
 args    : File::Temp::Dir object
 returns : File::Temp::Dir object

=cut

has 'tempdir' => (is => 'rw', isa => 'File::Temp::Dir');

=head2 cleanup

 usage   : used internally
 function: whether or not to delete the temporary files
 args    : boolean
 returns : boolean

=cut

has 'cleanup' => (is => 'rw', isa => 'Bool', default => 1);

=head1 ROLES

 with 'Fist::Utils::Muscle';
 with 'Fist::Utils::Blast';
 with 'Fist::Utils::Hmmscan';
 with 'Fist::Utils::Hmmalign';

=cut

with 'Fist::Utils::Blast';
with 'Fist::Utils::Muscle';
with 'Fist::Utils::Kalign';
with 'Fist::Utils::Hmmalign';

=head1 METHODS

=cut

=head2 max_len

 usage   :
 function: get the maximum length of any of the sequences in this object
 args    :
 returns : an integer

=cut

sub max_len {
    my($self) = @_;

    my $longest_seq = (sort {$b->len <=> $a->len} $self->seqs)[0];

    return $longest_seq->len;
}

=head2 align

 usage   :
 function: align sequences with muscle (max_len < 10000) or kalign (max_len >= 10000)
 args    :
 returns : a Bio::Align::AlignI compliant object, or undef on error

=cut

sub align {
    my($self) = @_;

    #return(($self->max_len < 10000) ? $self->run_muscle : $self->run_kalign);
    return $self->run_kalign;
}

1;
