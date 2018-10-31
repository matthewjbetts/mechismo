package Fist::Utils::Counts;

use Moose;
use JSON::Any;
use Carp ();
use namespace::autoclean;

=head1 NAME

 Fist::Utils::Counts

=cut

=head1 ACCESSORS

=cut

=head1 METHODS

=cut

=head2 bin

 usage   :
 function:
 args    :
 returns :

=cut

sub bin {
    my($value, $bin_size) = @_;

    my $bin;

    defined($bin_size) or Carp::cluck('bin_size undefined');

    $bin = sprintf "%.0f", $value / $bin_size;
    ($bin eq "-0") and ($bin = 0);

    return $bin;
}

=head2 parse_cons

 usage   :
 function:
 args    :
 returns :

=cut

sub parse_cons {
    my($schema, $fn) = @_;

    my $cons;
    my $fh;
    my @headings;
    my @F;
    my %hash;
    my $gn;
    my $ac;
    my $given_res;
    my $res;
    my $pos;
    my @seqs;
    my $seq;
    my $rRCS;
    my $n_found;
    my $n_mismatch;
    my $id_p;

    if($fn =~ /\.gz\Z/) {
        if(!open($fh, "zcat $fn |")) {
            warn "Error: parse_cons: cannot open pipe from 'zcat $fn'.";
            return undef;
        }
    }
    else {
        if(!open($fh, $fn)) {
            warn "Error: parse_cons: cannot open '$fn' file for reading.";
            return undef;
        }
    }

    $_ = <$fh>;
    chomp $_;
    $_ =~ s/^#//;
    @headings = split /\t/, $_;
    $cons = {};
    $n_found = 0;
    $n_mismatch = 0;
    $id_p = '';
    while(<$fh>) {
        chomp;
        @F = split /\t/;
        @hash{@headings} = @F;

        if($hash{Id} ne $id_p) {
            $seq = undef;
            if($hash{Id} =~ /\A(\S+)\|(\S+)\Z/) {
                ($gn, $ac) = ($1, $2);
                @seqs = $schema->resultset('Seq')->search({'aliases.alias' => $ac, 'aliases.type' => 'UniProtKB accession'}, {join => 'aliases'})->all;
                if(@seqs == 0) {
                    warn "Error: parse_cons: no sequence with UniProtKB-accession '$ac' found.";
                }
                elsif(@seqs > 1) {
                    warn "Warning: parse_cons: more than one sequence with UniProtKB accession '$ac' found. Using first.";
                }
                $seq = $seqs[0];
            }
            else {
                warn "Error: parse_cons: cannot parse id '", $hash{Id}, "'";
            }
        }
        $id_p = $hash{Id};
        defined($seq) or next;

        $rRCS = $hash{rRCS};

        if($hash{residue} =~ /\A([A-Z])(\d+)\Z/) {
            ($given_res, $pos) = ($1, $2);
            $res = substr $seq->seq, $pos - 1, 1;
            #print "'", join("', '", 'RES', $given_res, $res, $seq->len, $seq->seq), "'\n";
            if($res ne $given_res) {
                warn "Error: parse_cons: given res '$given_res' does not match res '$res' at position $pos in seq '$ac'.";
                ++$n_mismatch;
                next;
            }
        }
        else {
            warn "Error: parse_cons: cannot parse id '", $hash{Id}, "'";
            next;
        }

        ++$n_found;
        $cons->{$seq->id}->{$pos} = $rRCS / 100;
    }
    warn sprintf "Fist::Utils::Counts::parse_cons: mismatches: %d / %d (%.2f)", $n_mismatch, $n_mismatch + $n_found, $n_mismatch / ($n_mismatch + $n_found);

    return $cons;
}

=head2 parse_de_cons

 usage   :
 function:
 args    :
 returns :

=cut

sub parse_de_cons {
    my($schema, $fn) = @_;

    my $cons;
    my $fh;
    my @F;
    my $gn;
    my $ac;
    my $ac_p;
    my @seqs;
    my $seq;
    my $given_res;
    my $pos;
    my $res;
    my $n_de;
    my $n_same;
    my $n_diff;
    my $n_mismatch;
    my $total;

    if($fn =~ /\.gz\Z/) {
        if(!open($fh, "zcat $fn |")) {
            warn "Error: parse_cons: cannot open pipe from 'zcat $fn'.";
            return undef;
        }
    }
    else {
        if(!open($fh, $fn)) {
            warn "Error: parse_cons: cannot open '$fn' file for reading.";
            return undef;
        }
    }

    $cons = {};
    $ac_p = '';
    $n_mismatch = 0;
    while(<$fh>) {
        #shd|Q9VUF8      7227    F70     partner_bg-phosphorylation      opiNOG11007     0|7|10
        #WFIKKN2|Q8TEU8  9606    R238    partner_bg-phosphorylation      opiNOG08467     0|18|13

        /^#/ and next;
        @F = split /\t/;
        ($gn, $ac) = split /\|/, $F[0];
        if($ac ne $ac_p) {
            @seqs = $schema->resultset('Seq')->search({'aliases.alias' => $ac, 'aliases.type' => 'UniProtKB accession'}, {join => 'aliases'})->all;
            if(@seqs == 0) {
                warn "Error: parse_de_cons: no sequence with UniProtKB-accession '$ac' found.";
            }
            elsif(@seqs > 1) {
                warn "Warning: parse_de_cons: more than one sequence with UniProtKB accession '$ac' found. Using first.";
            }
            $seq = $seqs[0];
        }
        $ac_p = $ac;

        if($F[2] =~ /\A([ACDEFGHIKLMNPQRSTVWY])(\d+)/) {
            ($given_res, $pos) = ($1, $2);
        }
        else {
            warn "Error: parse_de_cons: cannot parse res info '$F[1]'.";
            next;
        }
        $res = substr $seq->seq, $pos - 1, 1;

        if($res ne $given_res) {
            warn "Error: parse_de_cons: given res '$given_res' does not match res '$res' at position $pos in seq '$ac'.";
            ++$n_mismatch;
            next;
        }

        ($n_de, $n_same, $n_diff) = split /\|/, $F[5];
        $total = $n_de + $n_same + $n_diff;
        $cons->{$seq->id}->{$pos} = {
                                     cons    => $n_same / $total,
                                     de      => $n_de / $total,
                                     de_cons => ($n_de + $n_same) / $total,
                                     total   => $total,
                                    };
    }
    close($fh);

    return $cons;
}

1;
