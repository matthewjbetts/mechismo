package Fist::IO::Ecod;

use Moose;
use Carp ();
use Fist::NonDB::Ecod;
use Fist::NonDB::Frag;
use Fist::NonDB::ChainSegment;
use Fist::NonDB::SeqGroup;
use Fist::NonDB::Seq;
use namespace::autoclean;

=head1 NAME

 Fist::IO::Scop

=cut

=head1 ROLES

 with 'Fist::IO';

=cut

with 'Fist::IO';

=head1 METHODS

=cut

=head2 parse_ecod_latest_domains

 usage   : $self->parse_ecod_latest_domains($fn);
 function: parse ecod.latest.domains.txt file
 args    : file name
 returns : hash

=cut

# FIXME - this does not refer directly to Ecod objects,
# rather to the source ecod file, so probably belongs
# somewhere else

sub parse_ecod_latest_domains {
    my($self, $fn) = @_;

    my $id;
    my $id_ecod;
    my $ecod;
    my $pdb;
    my $domain;
    my $fh;
    my @headings;
    my @F;
    my %hash;
    my $range;
    my $x;
    my $h;
    my $t;
    my $f;
    my $cid;
    my $resSeq1;
    my $resSeq2;
    my $iCode1;
    my $iCode2;
    my $large;
    my $idcode;

    $ecod = {pdbs => {}, hierarchy => {}};
    if(!open($fh, $fn)) {
        warn "Error: parse_ecod: cannot open '$fn' file for reading.";
        return undef;
    }
    $id = 0;
    while(<$fh>) {
        if(s/^#uid/uid/) {
            chomp;
            @headings = split /\t/;
        }
        elsif(/^#/) {
            next;
        }
        else {
            chomp;
            @F = split /\t/;
            @hash{@headings} = @F;
            ($x, $h, $t, $f) = split(/\./, $hash{f_id}, 4);
            defined($ecod->{hierarchy}->{$x}) or ($ecod->{hierarchy}->{$x} = {id => ++$id, name => ($hash{x_name} eq 'NO_X_NAME') ? '' : $hash{x_name} , h => {}});
            defined($ecod->{hierarchy}->{$x}->{hs}->{$h}) or ($ecod->{hierarchy}->{$x}->{hs}->{$h} = {id => ++$id, name => ($hash{h_name} eq 'NO_H_NAME') ? '' : $hash{h_name}, ts => {}});
            defined($ecod->{hierarchy}->{$x}->{hs}->{$h}->{ts}->{$t}) or ($ecod->{hierarchy}->{$x}->{hs}->{$h}->{ts}->{$t} = {id => ++$id, name => ($hash{t_name} eq 'NO_T_NAME') ? '' : $hash{t_name}, fs => {}});
            if(defined($f)) {
                defined($ecod->{hierarchy}->{$x}->{hs}->{$h}->{ts}->{$t}->{fs}->{$f}) or ($ecod->{hierarchy}->{$x}->{hs}->{$h}->{ts}->{$t}->{fs}->{$f} = {id => ++$id, name => $hash{f_name}});
                $id_ecod = $ecod->{hierarchy}->{$x}->{hs}->{$h}->{ts}->{$t}->{fs}->{$f}->{id};
            }
            else {
                $f = '';
                $id_ecod = $ecod->{hierarchy}->{$x}->{hs}->{$h}->{ts}->{$t}->{id};
            }

            if(!defined($pdb = $ecod->{pdbs}->{$hash{pdb}})) {
                $pdb = {idcode => $hash{pdb}, domains => []};
                $ecod->{pdbs}->{$hash{pdb}} = $pdb;
            }

            $domain = {id => $hash{ecod_domain_id}, id_ecod => $id_ecod, hierarchy => [$x, $h, $t, $f], ranges => []};
            push @{$pdb->{domains}}, $domain;
            foreach $range (split /,/, $hash{pdb_range}) {
                if($range =~ /\A(\S+?):(-{0,1}[\d]+)(\S{0,1}?)-(-{0,1}[\d]+)(\S{0,1})\Z/) {
                    ($cid, $resSeq1, $iCode1, $resSeq2, $iCode2) = ($1, $2, $3, $4, $5);
                    ($iCode1 eq '') and ($iCode1 = ' ');
                    ($iCode2 eq '') and ($iCode2 = ' ');
                    push @{$domain->{ranges}}, [$cid, $resSeq1, $iCode1, $cid, $resSeq2, $iCode2];
                    if(length($cid) > 1) {
                        $large->{$pdb->{idcode}}->{$cid}++;
                        #print join("\t", 'MULTICHAIN', $x, $h, $t, $f, $id_ecod, $hash{f_name}, $pdb->{idcode}, $cid), "\n";
                    }
                }
                elsif($range =~ /\A(\S+?):(-{0,1}[\d]+)(\S{0,1})\Z/) {
                    ($cid, $resSeq1, $iCode1) = ($1, $2, $3);
                    ($iCode1 eq '') and ($iCode1 = ' ');
                    push @{$domain->{ranges}}, [$cid, $resSeq1, $iCode1, $cid, $resSeq1, $iCode1];
                    if(length($cid) > 1) {
                        $large->{$pdb->{idcode}}->{$cid}++;
                        #print join("\t", 'MULTICHAIN', $x, $h, $t, $f, $id_ecod, $hash{f_name}, $pdb->{idcode}, $cid), "\n";
                    }
                }
                else {
                    warn "Warning: do not understand '", $pdb->{idcode}, "', range '", $range, "'";
                }
            }
        }
    }
    close($fh);

    #foreach $idcode (sort keys %{$large}) {
    #    warn "Warning: multi-letter chain identifier(s) for '$idcode': ", join(', ', sort keys %{$large->{$idcode}}), '.';
    #}

    return $ecod;
}

=head2 output_ecod_hierarchy

 usage   : $self->output_ecod_hierarchy($ecod, $fh);
 function: parse ecod.latest.domains.txt file
 args    : ecod hash and a file name
 returns :

=cut

# FIXME - this does not refer directly to Ecod objects,
# rather to the source ecod file, so probably belongs
# somewhere else

sub output_ecod_hierarchy {
    my($self, $ecod, $fh) = @_;

    my $x;
    my $h;
    my $t;
    my $f;

    foreach $x (sort {$a <=> $b} keys %{$ecod->{hierarchy}}) {
        print $fh join("\t", $ecod->{hierarchy}->{$x}->{id}, $x, ('\N') x 3, $ecod->{hierarchy}->{$x}->{name}), "\n";
        foreach $h (sort {$a <=> $b} keys %{$ecod->{hierarchy}->{$x}->{hs}}) {
            print $fh join("\t", $ecod->{hierarchy}->{$x}->{hs}->{$h}->{id}, $x, $h, ('\N') x 2, $ecod->{hierarchy}->{$x}->{hs}->{$h}->{name}), "\n";
            foreach $t (sort {$a <=> $b} keys %{$ecod->{hierarchy}->{$x}->{hs}->{$h}->{ts}}) {
                print $fh join("\t", $ecod->{hierarchy}->{$x}->{hs}->{$h}->{ts}->{$t}->{id}, $x, $h, $t, '\N', $ecod->{hierarchy}->{$x}->{hs}->{$h}->{ts}->{$t}->{name}), "\n";
                foreach $f (sort {$a <=> $b} keys %{$ecod->{hierarchy}->{$x}->{hs}->{$h}->{ts}->{$t}->{fs}}) {
                    print $fh join("\t", $ecod->{hierarchy}->{$x}->{hs}->{$h}->{ts}->{$t}->{fs}->{$f}->{id}, $x, $h, $t, $f, $ecod->{hierarchy}->{$x}->{hs}->{$h}->{ts}->{$t}->{fs}->{$f}->{name}), "\n";
                }
            }
        }
    }
}

=head2 tsv_id_map

 usage   : $self->tsv_id_map($id_mapping, $id_to_space, \*STDOUT);
 function: parse tsv file, assign new unique identifiers,
           store mapping of new to old in id mapping hash.
 args    : Fist::Utils::IdMapping object, string, file handle GLOB
 returns : 1 on success, 0 on failure

=cut

sub tsv_id_map {
    my($self, $id_mapping, $id_to_space, $fh_out) = @_;

    my $fh;
    my $id_old;
    my $x;
    my $h;
    my $t;
    my $f;
    my $name;
    my $id_new;

    $fh = $self->fh;
    while(<$fh>) {
        chomp;
        ($id_old, $x, $h, $t, $f, $name) = split /\t/;
        $id_new = $id_mapping->id_new($id_to_space->{id}, 'Ecod', $id_old);
        print $fh_out join("\t", $id_new, $x, $h, $t, $f, $name), "\n";
    }

    return 1;
}

=head2 resultset_name

 usage   :
 function: used internally to provide the result set name
 args    : none
 returns : the name of the result set

=cut

sub resultset_name {
    return 'Ecod';
}

=head2 column_names

 usage   :
 function: used internally to provide the column names in order used by tsv files
 args    : none
 returns : a list of column names

=cut

sub column_names {
    return(qw/id x h t f name/);
}

__PACKAGE__->meta->make_immutable;
1;
