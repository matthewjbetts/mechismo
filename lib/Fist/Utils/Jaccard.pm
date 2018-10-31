package Fist::Utils::Jaccard;

use Moose;
use Carp ();
use namespace::autoclean;

=head1 NAME

 Fist::Utils::Overlap

=cut

=head1 ACCESSORS

=cut

=head1 ROLES

=cut

=head1 METHODS

=cut

=head2 calc

 usage   :
 function:
 args    :
 returns :

=cut

sub calc {
    my($set1, $set2) = @_;

    my $hash1;
    my $hash2;
    my $tmp;
    my $n1;
    my $n2;
    my $intersection;
    my $union;
    my $jaccard;
    my $key;

    defined($hash1 = _to_hash($set1)) or return(undef);
    defined($hash2 = _to_hash($set2)) or return(undef);

    $n1 = scalar keys %{$hash1};
    $n2 = scalar keys %{$hash2};

    $intersection = 0;
    if($n1 <= $n2) {
        foreach $key (keys %{$hash1}) {
            defined($hash2->{$key}) and ++$intersection;
        }
    }
    else {
        foreach $key (keys %{$hash2}) {
            defined($hash1->{$key}) and ++$intersection;
        }
    }
    $union = $n1 + $n2 - $intersection;
    $jaccard = $union ? ($intersection / $union) : 0;

    return $jaccard;
}

sub _to_hash {
    my($set) = @_;

    my $ref;
    my $hash;

    $ref = ref $set;
    ($ref eq '') and ($ref = 'SCALAR');

    if($ref eq 'HASH') {
        $hash = $set;
    }
    elsif($ref eq 'ARRAY') {
        $hash = {};
        foreach $a (@{$set}) {
            $hash->{$a}++;
        }
    }
    else {
        Carp::cluck("don't know how to convert $ref to a HASH.");
        return undef;
    }

    return $hash;
}

__PACKAGE__->meta->make_immutable;
1;
