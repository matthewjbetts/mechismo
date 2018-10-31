package Fist::Utils::SubstitutionMatrix;

use Moose;
use Carp ();
use namespace::autoclean;

my $mapping = {};

=head1 NAME

 Fist::Utils::SubstitutionMatrix

=cut

=head1 ACCESSORS

=cut

=head2 fn

 usage   : name of file containing the substitution matrix
 function:
 args    :
 returns :

=cut

has 'fn' => (is  => 'ro', isa => 'Str', required => 1);

=head2 format

 usage   : format of file containing the substitution matrix
 function:
 args    :
 returns :

=cut

has 'format' => (is  => 'ro', isa => 'Str', required => 1);

=head2 _matrix

 usage   : the substitution matrix, assigned when the object is built. Set it yourself at your own peril.
 function:
 args    :
 returns :

=cut

has '_matrix' => (is  => 'rw', isa => 'HashRef[Any]');

=head2 min

 usage   : the minimum value, assigned when the object is built. Set it yourself at your own peril.
 function:
 args    :
 returns :

=cut

has 'min' => (is  => 'rw', isa => 'Num');

=head2 max

 usage   : the maximum value, assigned when the object is built. Set it yourself at your own peril.
 function:
 args    :
 returns :

=cut

has 'max' => (is  => 'rw', isa => 'Num');

=head1 METHODS

=cut

=head2 BUILD

 usage   : (called when the object is constructed, you shouldn't need to call it directly)
 function: parses the given file name assuming the given format
 args    :
 returns :

=cut

sub BUILD {
    my($self) = @_;

    my $fn = $self->fn;
    my $format = $self->format;
    my $fh;
    my @AAs;
    my @row;
    my $aa_row;
    my $line_n;
    my $i;
    my $matrix = {};
    my $class;
    my $aa;
    my $lo;
    my @values;

    if(!open($fh, $fn)) {
        Carp::cluck("cannot open '$fn' file for reading");
        return undef;
    }

    if($format =~ /\Ancbi\Z/i) {
        $line_n = 0;
        while(<$fh>) {
            ++$line_n;
            (/^#/ or /\A\s*\Z/) and next;
            if(s/\A\s+//) {
                @AAs = split;
            }
            else {
                @row = split;
                $aa_row = shift @row;
                if(@row != @AAs) {
                    Carp::cluck("number of column headings and number of entries does not match in '$fn' file on line $line_n");
                    return undef;
                }
                $matrix->{$aa_row} = {};
                @{$matrix->{$aa_row}}{@AAs} = @row;
            }
        }
    }
    elsif($format =~ /\Ainterprets\Z/i) {
        $line_n = 0;
        $i = 0;
        while(<$fh>) {
            ++$line_n;
            if($_ =~ /\A\s*\Z/) {
                next;
            }
            elsif($_ =~ s/^#\s*//) {
                @AAs = split;
            }
            elsif($_ =~ s/^\s*//) {
                @row = split;
                if(@row != @AAs) {
                    Carp::cluck("number of column headings and number of entries does not match in '$fn' file on line $line_n");
                    return undef;
                }
                $aa_row = $AAs[$i];

                $matrix->{$aa_row} = {};
                @{$matrix->{$aa_row}}{@AAs} = @row;

                $i++;
            }
        }
    }
    elsif($format =~ /\Aprot_chem_class\Z/i) {
        $line_n = 0;
        while(<$fh>) {
            ++$line_n;
            if(/\A\s*\Z/ or /^#/) {
                next;
            }
            else {
                ($class, $aa, $lo) = split;
                $matrix->{$class}->{$aa} = $lo;
            }
        }
    }
    else {
        Carp::cluck("unrecognised file format '$format'");
        return undef;
    }
    close($fh);
    $self->_matrix($matrix);

    @values = sort {$a <=> $b} $self->values;
    $self->min($values[0]);
    $self->max($values[$#values]);

    return $self;
}

=head2 AAs

 usage   : @AAs = $matrix->AAs;
 function: returns the single-character amino-acid codes
 args    : none
 returns : a list of amino-acid codes

=cut

sub AAs {
    my($self) = @_;

    my @AAs;

    @AAs = sort _by_aa keys %{$self->_matrix};

    return @AAs;
}

my $codes = {
             A => 'Alanine',
             R => 'Arginine',
             N => 'Asparagine',
             D => 'Aspartate',
             C => 'Cysteine',
             Q => 'Glutamine',
             E => 'Glutamate',
             G => 'Glycine',
             H => 'Histidine',
             I => 'Isoleucine',
             L => 'Leucine',
             K => 'Lysine',
             M => 'Methionine',
             F => 'Phenylalanine',
             P => 'Proline',
             S => 'Serine',
             T => 'Threonine',
             W => 'Tryptophan',
             Y => 'Tyrosine',
             V => 'Valine',
            };


sub _by_aa {
    my $cmp;

    my $name1;
    my $name2;

    if(defined($name1 = $codes->{$a}) and defined($name2 = $codes->{$b})) {
        $cmp = $name1 cmp $name2;
    }
    elsif($a eq '*') {
        $cmp = 1;
    }
    elsif($b eq '*') {
        $cmp = -1;
    }
    else {
        $cmp = $a cmp $b;
    }

    return $cmp;
}

=head2 value

 usage   : $value = $matrix->value($a, $b);
 function: returns the matrix value for the given pair of amino-acids
 args    : two single-character amino-acid codes
 returns : a value

=cut

sub value {
    my($self, $a, $b) = @_;

    my $value;

    $| = 1;

    if(!defined($a)) {
        Carp::cluck("\$a undefined");
        $a = 'big';
    }

    if(!defined($b)) {
        Carp::cluck("\$b undefined");
        $b = 'big';
    }

    defined($self->_matrix->{$a}) or ($a = 'big');
    defined($self->_matrix->{$a}->{$b}) or ($b = 'big');
    #$value = (defined($self->_matrix->{$a}) and defined($self->_matrix->{$a}->{$b})) ? $self->_matrix->{$a}->{$b} : 0;
    $value = $self->_matrix->{$a}->{$b};

    return $value;
}

=head2 values

 usage   : @values = $matrix->values;
 function: get a a list of all matrix values
 args    :
 returns : a list

=cut

sub values {
    my($self) = @_;

    my @values;
    my $a;

    @values = ();
    foreach $a (keys %{$self->_matrix}) {
        push @values, values %{$self->_matrix->{$a}};
    }

    return @values;
}

=head2 min_zero

 usage   : $matrix->min_zero
 function: subtract the minimum value from all values, making zero the new minimum
 args    :
 returns :

=cut

sub min_zero {
    my($self) = @_;

    my @values;
    my $a;

    @values = ();
    foreach $a (keys %{$self->_matrix}) {
        foreach $b (keys %{$self->_matrix->{$a}}) {
            $self->_matrix->{$a}->{$b} -= $self->min;
        }
    }
    $self->max($self->max - $self->min);
    $self->min(0);
}

=head2 delta

 usage   : $value = $matrix->value($a1, $b1, $a2, $b2);
 function: returns the difference in the matrix value for the two given pairs of amino-acids
           (this makes more sense for pair-potential matrices rather than for normal substitution matrices)
 args    : four single-character amino-acid codes
 returns : a value

=cut

sub delta {
    my($self, $a1, $b1, $a2, $b2) = @_;

    my $value1;
    my $value2;
    my $delta;

    #$value1 = (defined($self->_matrix->{$a1}) and defined($self->_matrix->{$a1}->{$b1})) ? $self->_matrix->{$a1}->{$b1} : 0;
    #$value2 = (defined($self->_matrix->{$a2}) and defined($self->_matrix->{$a2}->{$b2})) ? $self->_matrix->{$a2}->{$b2} : 0;
    $value1 = $self->value($a1, $b1);
    $value2 = $self->value($a2, $b2);
    $delta = (defined($value1) and defined($value2)) ? ($value2 - $value1) : undef;

    return $delta;
}

=head2 output

 usage   :
 function: output the substitution matrix to a file handle
 args    : a file handle and an optional format (default is format initially parsed)
 returns : 1 on success, 0 on failure

=cut

sub output {
    my($self, $fh, $format) = @_;

    my @AAs;
    my $i;
    my $j;
    my $aa1;
    my $aa2;

    defined($format) or ($format = $self->format);

    @AAs = $self->AAs;
    if($format =~ /\Ancbi\Z/i) {
        # headings
        print $fh ' ';
        for($j = 0; $j < @AAs; $j++) {
            printf $fh "%3s", $AAs[$j];
        }
        print $fh "\n";

        # rows
        for($i = 0; $i < @AAs; $i++) {
            $aa1 = $AAs[$i];
            print $fh $aa1;
            for($j = 0; $j < @AAs; $j++) {
                $aa2 = $AAs[$j];
                printf $fh "%3d", $self->value($aa1, $aa2);
            }
            print $fh "\n";
        }
    }
    elsif($format =~ /\Ainterprets\Z/i) {
        # headings
        print $fh '#', join(' ', @AAs), "\n";

        # rows
        for($i = 0; $i < @AAs; $i++) {
            $aa1 = $AAs[$i];
            for($j = 0; $j < @AAs; $j++) {
                $aa2 = $AAs[$j];
                printf $fh " %.2f", $self->value($aa1, $aa2);
            }
            print $fh "\n";
        }
    }
    elsif($format =~ /\Aoc\Z/i) {
        print $fh join("\n", scalar @AAs, @AAs), "\n"; # number of AAs and then their labels

        # upper diagonal of matrix
        for($i = 0; $i < @AAs; $i++) {
            $aa1 = $AAs[$i];
            for($j = $i + 1; $j < @AAs; $j++) {
                $aa2 = $AAs[$j];
                printf $fh "%.2f\n", $self->value($aa1, $aa2);
            }
        }
    }
    else {
        Carp::cluck("unrecognised file format '$format'");
        return 0;
    }

    return 1;
}

1;
