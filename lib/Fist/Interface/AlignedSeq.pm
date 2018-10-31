package Fist::Interface::AlignedSeq;

use Moose::Role;

=head1 NAME

 Fist::Interface::AlignedSeq

=cut

=head1 ACCESSORS

=cut

=head2 id_aln

 usage   :
 function:
 args    :
 returns :

=cut

requires 'id_aln';

=head2 id_seq

 usage   :
 function:
 args    :
 returns :

=cut

requires 'id_seq';

=head2 seq

 usage   :
 function:
 args    :
 returns :

=cut

requires 'seq';

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

=head2 _edit_str

 usage   :
 function:
 args    :
 returns :

=cut

requires '_edit_str';

=head2 _edits

 usage   :
 function:
 args    :
 returns :

=cut

has '_edits' => (is => 'rw', isa => 'ArrayRef[Str]');

=head2 _aseq

 usage   :
 function:
 args    :
 returns :

=cut

has '_aseq' => (is => 'rw', isa => 'Str');

=head1 ROLES

=cut

=head1 METHODS

=cut

# _edit_str and edit_str(), _edits and edits(), and _aseq and aseq()
# rather than using around so that in the wrapper of one method I can
# avoid the wrappers of others, otherwise I'd end up with an infinite
# recursion of calls... looks like I could also avoid this with some
# Moose jiggery-pokery (has_value?) but this should be quicker

sub edit_str {
    my($self, $edit_str) = @_;

    my $edits;

    if(defined($edit_str)) {
        $self->_edit_str($edit_str);
    }
    elsif(!defined($edit_str = $self->_edit_str)) {
        if(defined($edits = $self->edits)) {
            $edit_str = join(',', @{$edits});
            $self->_edit_str($edit_str);
        }
        else {
            Carp::cluck('no edits');
            return undef;
        }
    }

    return $edit_str;
}

sub edits {
    my($self, $edits) = @_;

    my $edit_str;
    my $aseq;

    if(defined($edits)) {
        $self->_edits($edits);
    }
    elsif(!defined($edits = $self->_edits)) {
        if(defined($edit_str = $self->_edit_str)) {
            $edits = $self->_calc_edits_from_str($edit_str);
            $self->_edits($edits);
        }
        elsif(defined($aseq = $self->_aseq)) {
            $edits = $self->_calc_edits_from_aseq($aseq);
            $self->_edits($edits);
        }
    }

    return $edits;
};

sub aseq {
    my($self, $aseq, $seq) = @_;

    my $edits;
    my $edit_str;

    if(defined($aseq)) {
        $self->_aseq($aseq);
    }
    elsif(!defined($aseq = $self->_aseq)) {
        if(defined($edits = $self->_edits)) {
            $aseq = $self->_calc_aseq_from_edits($edits, $seq);
            $self->_aseq($aseq);
        }
        elsif(defined($edit_str = $self->_edit_str)) {
            $edits = $self->_calc_edits_from_str($edit_str);
            $self->_edits($edits);
            $aseq = $self->_calc_aseq_from_edits($edits, $seq);
            $self->_aseq($aseq);
        }
        else {
            Carp::cluck('no edits or edit_str');
            return undef;
        }
    }

    return $aseq;
};

sub _calc_aseq_from_edits {
    my($self, $edits, $seq) = @_;

    my $aseq;
    my $start;
    my $edit;

    if(!defined($seq)) {
        if(!defined($seq = $self->seq)) {
            Carp::cluck('seq undefined');
            return undef;
        }
    }
    $seq = $seq->seq;

    $aseq = [];
    $start = $self->start - 1;
    foreach $edit (@{$edits}) {
        if($edit < 0) {
            push @{$aseq}, '-' x abs($edit);
        }
        else {
            push @{$aseq}, substr($seq, $start, $edit);
            $start += $edit;
        }
    }
    $aseq = join '', @{$aseq};

    return $aseq;
}

sub _calc_edits_from_aseq {
    my($self, $aseq) = @_;

    my $edits;
    my $edit;
    my $substr;
    my $l;

    $edits = [];
    foreach $substr (grep(!/\A\Z/, (split /(-+)/, $aseq))) {
        $l = length $substr;
        ($substr =~ /\A-/) and ($l *= -1);
        push @{$edits}, $l;
    }

    return $edits;
}

sub _calc_edits_from_str {
    my($self, $edit_str) = @_;

    my $edits;

    $edits = [split /,/, $edit_str];

    return $edits;
}

sub output_tsv {
    my($self, $fh) = @_;

    print $fh join("\t", $self->id_aln, $self->id_seq, $self->start, $self->end, $self->_edit_str), "\n";
}

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
             id_aln => $self->id_aln,
             id_seq => $self->id_seq,
             start  => $self->start,
             end    => $self->end,
             edits  => $self->edits,
             aseq   => $self->aseq,
            };

    return $json;
}

1;
