package Fist::Utils::Overlap;

use Moose;
use Carp ();
use namespace::autoclean;

=head1 NAME

 Fist::Utils::Overlap

=cut

=head1 ACCESSORS

=cut

=head2 start1

 usage   :
 function:
 args    :
 returns :

=cut

has 'start1' => (is  => 'ro', isa => 'Int', required => 1);

=head2 end1

 usage   :
 function:
 args    :
 returns :

=cut

has 'end1' => (is  => 'ro', isa => 'Int', required => 1);

=head2 len1

 usage   : print $self->len1;
           Calculated when the object is built. Set it yourself at your own peril.
 function:
 args    : none
 returns : $end1 - $start1 + 1

=cut

has 'len1' => (is  => 'rw', isa => 'Int');

=head2 start2

 usage   :
 function:
 args    :
 returns :

=cut

has 'start2' => (is  => 'ro', isa => 'Int', required => 1);

=head2 end2

 usage   :
 function:
 args    :
 returns :

=cut

has 'end2' => (is  => 'ro', isa => 'Int', required => 1);

=head2 len2

 usage   : print $self->len2;
           Calculated when the object is built. Set it yourself at your own peril.
 function:
 args    : none
 returns : $end2 - $start2 + 1

=cut

has 'len2' => (is  => 'rw', isa => 'Int');

=head2 overlap

 usage   : print $self->overlap;
           Calculated when the object is built. Set it yourself at your own peril.
 function:
 args    : none
 returns : the size of the overlap

=cut

has 'overlap' => (is  => 'rw', isa => 'Int');

=head2 f1

 usage   : print $self->f1;
           Calculated when the object is built. Set it yourself at your own peril.
 function:
 args    : none
 returns : the fraction of item 1 that overlaps

=cut

has 'f1' => (is  => 'rw', isa => 'Num');

=head2 f2

 usage   : print $self->f2;
           Calculated when the object is built. Set it yourself at your own peril.
 function:
 args    : none
 returns : the fraction of item 2 that overlaps

=cut

has 'f2' => (is  => 'rw', isa => 'Num');

=head2 jaccard

 usage   : print $self->jaccard;
           Calculated when the object is built. Set it yourself at your own peril.
 function:
 args    : none
 returns : the jaccard index of the overlap

=cut

has 'jaccard' => (is  => 'rw', isa => 'Num');

=head2 dl

 usage   : print $self->dl;
           Calculated when the object is built. Set it yourself at your own peril.
 function:
 args    : none
 returns : the size of the left-hand overhang

=cut

has 'dl' => (is  => 'rw', isa => 'Int');

=head2 dr

 usage   : print $self->dr;
           Calculated when the object is built. Set it yourself at your own peril.
 function:
 args    : none
 returns : the size of the right-hand overhang

=cut

has 'dr' => (is  => 'rw', isa => 'Int');

=head2 left_order

 usage   : print $self->left_order;
           Calculated when the object is built. Set it yourself at your own peril.
 function:
 args    : none
 returns : The order of the fragments starting from the left:
             -1 if start1 < start2 (ie. start1 is leftmost)
              0 if they are the same
             +1 if start1 > start2

=cut

has 'left_order' => (is  => 'rw', isa => 'Int');

=head2 right_order

 usage   : print $self->right_order;
           Calculated when the object is built. Set it yourself at your own peril.
 function:
 args    : none
 returns : The order of the fragments starting from the right:
             -1 if end1 > end2 (ie. end1 is rightmost)
              0 if they are the same
             +1 if end1 < end2

=cut

has 'right_order' => (is  => 'rw', isa => 'Int');

=head2 containment

 usage   : print $self->overlap;
           Calculated when the object is built. Set it yourself at your own peril.
 function:
 args    : none
 returns : -1 when start1 and end1 completely contain start2 and end2, + 1 if vice-versa, and zero otherwise

=cut

has 'containment' => (is  => 'rw', isa => 'Int');

=head1 ROLES

=cut

=head1 METHODS

=cut

sub BUILD {
    my($self) = @_;

    ($self->start1 > $self->end1) and confess("start1 must be <= end1");
    ($self->start2 > $self->end2) and confess("start2 must be <= end2");

    $self->_calc();
}

=head2 _calc

 usage   : (called when the object is constructed, you shouldn't need to call it directly)
 function: Takes the given positions (start1, end1, start2, end2) and
           calculates overlap, containment, overhang and order
 args    :
 returns :

=cut

sub _calc {
    my($self) = @_;

    $self->len1($self->end1 - $self->start1 + 1);
    $self->len2($self->end2 - $self->start2 + 2);
    $self->left_order($self->start1 <=> $self->start2);
    $self->right_order($self->end2 <=> $self->end1);

    if($self->start1 <= $self->start2) {
	if($self->end1 >= $self->start2) {
	    if($self->end1 >= $self->end2) {
		# ------------
		#     ----
		#
		# A contains B

		$self->overlap($self->end2 - $self->start2 + 1);
                $self->dl($self->start2 - $self->start1);
		$self->dr($self->end1 - $self->end2);
                $self->containment(-1);
	    }
	    else {
		# --------
		#     --------
		#
		# the end of A overlaps with the beginning of B

		$self->overlap($self->end1 - $self->start2 + 1);
		$self->dl($self->start2 - $self->start1);
		$self->dr($self->end2 - $self->end1);
                $self->containment(0);
	    }
	}
	else {
	    # ----
	    #       ----
	    #
	    # A is before B
	    $self->overlap(0);
	    $self->dl($self->end1 - $self->start1 + 1);
	    $self->dr($self->end2 - $self->start2 + 1);
            $self->containment(0);
	}
    }
    else {
	if($self->start1 <= $self->end2) {
	    if($self->end1 <= $self->end2) {
		#     ----
		# ------------
		#
		# A is contained by B
		$self->overlap($self->end1 - $self->start1 + 1);
		$self->dl($self->start1 - $self->start2);
		$self->dr($self->end2 - $self->end1);
                $self->containment(+1);
	    }
	    else {
		#     --------
		# --------
		#
		# the beginning of A overlaps with the end of B
		$self->overlap($self->end2 - $self->start1 + 1);
		$self->dl($self->start1 - $self->start2);
		$self->dr($self->end1 - $self->end2);
                $self->containment(0);
	    }
	}
	else {
	    #       ----
	    # ----
	    #
	    # A is after B
	    $self->overlap(0);
	    $self->dl($self->end2 - $self->start2 + 1);
	    $self->dr($self->end1 - $self->start1 + 1);
            $self->containment(0);
	}
    }

    $self->f1(100 * $self->overlap / $self->len1);
    $self->f2(100 * $self->overlap / $self->len2);
    $self->jaccard($self->overlap / ($self->dl + $self->overlap + $self->dr));

    return 1;
}

=head1 OVERLOADED OPERATORS

=cut

=head1 +

 usage   : $overlap3 = $overlap1 + $overlap2;
 function: overloads the '+' operator, calling plus()
 args    :
 returns : a new Fist::Utils::Overlap object

 FIXME - can't get overloading to work for some reason, use plus() directly for now

=cut

use overload '+' => \&plus, fallback => 1;

=head1 plus

 usage   : $overlap3 = Fist::Utils::Overlap::plus($overlap1 + $overlap2);
 function:
 args    :
 returns :

=cut

sub plus {
    my($overlap1, $overlap2, $swap) = @_;

    my $overlap3;

    $overlap3 = __PACKAGE__->new(
                                 start1 => ($overlap1->start1 <= $overlap2->start1) ? $overlap1->start1 : $overlap2->start1,
                                 end1   => ($overlap1->end1   >= $overlap2->end1)   ? $overlap1->end1   : $overlap2->end1,
                                 start2 => ($overlap1->start2 <= $overlap2->start2) ? $overlap1->start2 : $overlap2->start2,
                                 end2   => ($overlap1->end2   >= $overlap2->end2)   ? $overlap1->end2   : $overlap2->end2,
                                );
    warn "WARNING: containment may not be calculated correctly when summing overlaps.";
    $overlap3->containment(($overlap1->containment and $overlap2->containment) ? 1 : 0);

    return $overlap3;
}

__PACKAGE__->meta->make_immutable;
1;
