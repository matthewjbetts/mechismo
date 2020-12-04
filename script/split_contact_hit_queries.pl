#!/usr/bin/perl -w

use strict;

my $n_groups;
my $minPPIResRes;
my $minPDIResRes;
my $minPCIResRes;
my $min_lf_fist;
my $n_queries;
my $group_size;
my $fn_query;
my $fn_query_to_fist;
my $fn_frag_inst_to_fist;
my $fn_contacts;
my $dn;
my $queries;
my $fist_to_query;
my $frag_inst_to_seq;
my $contacts;

sub usage {
    my $prog;

    ($prog = __FILE__) =~ s/.*\///;

    die <<END;

Usage: $prog n_groups min_ppi_resres min_pdi_resres min_pci_resres min_lf_fist queries.txt.gz query_to_fist.tsv.gz frag_inst_to_fist.tsv.gz contacts_with_fist_numbers.gz

END
}

# FIXME - use GetArgs

defined($n_groups = shift @ARGV) or usage();
defined($minPPIResRes = shift @ARGV) or usage();
defined($minPDIResRes = shift @ARGV) or usage();
defined($minPCIResRes = shift @ARGV) or usage();
defined($min_lf_fist = shift @ARGV) or usage();
defined($fn_query = shift @ARGV) or usage();
defined($fn_query_to_fist = shift @ARGV) or usage();
defined($fn_frag_inst_to_fist = shift @ARGV) or usage();
defined($fn_contacts = shift @ARGV) or usage();

$dn = ($fn_query =~ /\A(\S+\/)/) ? $1 : "./";
defined($queries = parse_queries($fn_query)) or die;
defined($fist_to_query = get_fist_to_query($fn_query_to_fist, $min_lf_fist)) or die;
defined($frag_inst_to_seq = parse_frag_inst_to_seq($fn_frag_inst_to_fist, $fist_to_query)) or die;
defined($contacts = parse_contacts($fn_contacts, $frag_inst_to_seq, $minPPIResRes, $minPDIResRes, $minPCIResRes)) or die;

$n_queries = scalar keys %{$queries};
$group_size = sprintf "%.0f", $n_queries / $n_groups;

group($group_size, $queries, $contacts, $frag_inst_to_seq, $fist_to_query, $dn, $fn_query_to_fist);

sub group {
    my($group_size, $queries, $contacts, $frag_inst_to_seq, $fist_to_query, $dn, $fn_query_to_fist) = @_;

    my $i;
    my $links;
    my $id_sa2;
    my $id_sb2;
    my $id_sa1;
    my $id_sb1;
    my %visited;
    my @queue;
    my @members;
    my $group;
    my $n_members;
    my $n_group;
    my $size;
    my $groups;
    my $id_group;
    my $format_queries_fn;
    my $format_queries_to_fist_fn;
    my $fn_queries_split;
    my $fh_queries_split;
    my $fhs_queries_to_fist_split;
    my $fn_queries_to_fist_split;
    my $fh_queries_to_fist_split;
    my $query_to_group;
    my $fh_query_to_fist;
    my @F;

    $links = {};
    $i = 0;
    foreach $id_sa2 (keys %{$contacts}) {
        defined($fist_to_query->{$id_sa2}) or next;
        foreach $id_sb2 (keys %{$contacts->{$id_sa2}}) {
            defined($fist_to_query->{$id_sb2}) or next;
            foreach $id_sa1 (keys %{$fist_to_query->{$id_sa2}}) {
                foreach $id_sb1 (keys %{$fist_to_query->{$id_sb2}}) {
                    $links->{$id_sa1}->{$id_sb1}++;
                    $links->{$id_sb1}->{$id_sa1}++;
                }
            }
        }
    }

    #foreach $id_sa1 (sort {scalar(keys(%{$links->{$a}})) <=> scalar(keys(%{$links->{$b}}))} keys %{$links}) {
    #    print join("\t", 'NLINKS', $id_sa1, scalar keys %{$links->{$id_sa1}}), "\n";
    #}

    %visited = ();
    @queue = ();
    $groups = [];
    $group = [];
    foreach $id_sa1 (keys %{$queries}) {
        if(!$visited{$id_sa1}) {
            $visited{$id_sa1} = 1;

            @members = ();
            while(defined($id_sa1)) {
                push @members, $id_sa1;

                foreach $id_sa2 (keys %{$links->{$id_sa1}}) {
                    if(!$visited{$id_sa2}) {
                        $visited{$id_sa2} = 1;
                        push @queue, $id_sa2;
                    }
                }

                $visited{$id_sa1} = 2;
                $id_sa1 = shift @queue;
            }


            $n_members = scalar @members;
            if($n_members > 0) {
                #print join("\t", @members), "\n";

                $n_group = scalar @{$group};
                $size = $n_group + $n_members;
                if(($n_group > 0) and ($size > $group_size)) {
                    push @{$groups}, $group;
                    $group = [@members];
                }
                else {
                    push @{$group}, @members;
                }
            }
        }
    }
    (@{$group} > 0) and push(@{$groups}, $group);
    $format_queries_fn = sprintf "%s%%0%0dd.queries.txt", $dn, length(scalar(@{$groups}));
    $format_queries_to_fist_fn = sprintf "%s%%0%0dd.query_to_fist.tsv.gz", $dn, length(scalar(@{$groups}));
    $fhs_queries_to_fist_split = [];
    $query_to_group = {};
    for($id_group = 0; $id_group < @{$groups}; $id_group++) {
        $fn_queries_split = sprintf $format_queries_fn, $id_group;
        $fn_queries_to_fist_split = sprintf $format_queries_to_fist_fn, $id_group;
        if(!open($fh_queries_split, ">$fn_queries_split")) {
            warn "Error: group: cannot open '$fn_queries_split' file for writing.";
            return 0;
        }
        $group = $groups->[$id_group];
        print $fh_queries_split join("\n", @{$group}), "\n";
        close($fh_queries_split);

        if(!open($fhs_queries_to_fist_split->[$id_group], "| gzip > $fn_queries_to_fist_split")) {
            warn "Error: group: cannot open pipe to 'gzip > $fn_queries_to_fist_split'.";
            return 0;
        }
        foreach $id_sa1 (@{$group}) {
            $query_to_group->{$id_sa1} = $id_group;
        }
    }

    defined($fh_query_to_fist = myopen($fn_query_to_fist)) or return undef;
    while(<$fh_query_to_fist>) {
        @F = split /\t/;
        ($id_sa1, $id_sa2) = @F[4..5];
        if(!defined($id_group = $query_to_group->{$id_sa1})) {
            warn "Error: group: no group id for query '$id_sa1'.";
            next;
        }
        $fh_queries_to_fist_split = $fhs_queries_to_fist_split->[$id_group];
        print $fh_queries_to_fist_split $_;
    }
    close($fh_query_to_fist);

    foreach $fh_queries_to_fist_split (@{$fhs_queries_to_fist_split}) {
        close($fh_queries_to_fist_split);
    }
}

sub parse_frag_inst_to_seq {
    my($fn, $fist_to_query) = @_;

    my $fh;
    my $frag_inst_to_seq;
    my $id_fia2;
    my $id_sa2;

    defined($fh = myopen($fn)) or return undef;
    $frag_inst_to_seq = {};
    while(<$fh>) {
        ($id_fia2, $id_sa2) = split;
        defined($fist_to_query->{$id_sa2}) and ($frag_inst_to_seq->{$id_fia2} = $id_sa2);
    }
    close($fh);

    return $frag_inst_to_seq;
}

sub get_fist_to_query {
    my($fn, $min_lf_fist) = @_;

    my $fist_to_query;
    my $fh;
    my @F;
    my $id_aln;
    my $id_sa1;
    my $id_sa2;
    my $start_sa2;
    my $end_sa2;
    my $len_sa2;
    my $lf_sa2;

    defined($fh = myopen($fn)) or return undef;
    $fist_to_query = {};
    while(<$fh>) {
        @F = split /\t/;
        $id_aln = $F[0];
        ($id_sa1, $id_sa2) = @F[4..5];
        ($len_sa2, $start_sa2, $end_sa2) = @F[10..12];
        $lf_sa2 = ($end_sa2 - $start_sa2 + 1) / $len_sa2;
        ($lf_sa2 >= $min_lf_fist) or next;
        $fist_to_query->{$id_sa2}->{$id_sa1}->{$id_aln}++;
    }
    close($fh);

    return $fist_to_query;
}

sub parse_contacts {
    my($fn, $frag_inst_to_seq, $minPPIResRes, $minPDIResRes, $minPCIResRes) = @_;

    # store contacts by the fist sequences involved

    my $contacts;
    my $fh;
    my $id_contact;
    my $id_fia2;
    my $id_fib2;
    my $crystal;
    my $nres1;
    my $nres2;
    my $n_clash;
    my $n_resres;
    my $type;
    my $id_sa2;
    my $id_sb2;

    defined($fh = myopen($fn)) or return undef;
    $contacts = {};
    while(<$fh>) {
        ($id_contact, $id_fia2, $id_fib2, $crystal, $nres1, $nres2, $n_clash, $n_resres, $type) = split;

        #($crystal == 1) and next; # mechismoContactHits allows crystal contacts
        ($n_clash > 0) and next;
        ($type eq 'PPI') and ($n_resres < $minPPIResRes) and next;
        ($type eq 'PDI') and ($n_resres < $minPDIResRes) and next;
        ($n_resres < $minPCIResRes) and next; # FIXME - assumes minPCIResRes is less than minPPIResRes and minPDIResRes

        #print join("\t", 'CONTACT', $id_fia2, $id_fib2, defined($frag_inst_to_seq->{$id_fia2}) ? 'y' : 'n', defined($frag_inst_to_seq->{$id_fib2}) ? 'y' : 'n'), "\n";
        defined($id_sa2 = $frag_inst_to_seq->{$id_fia2}) or next;
        defined($id_sb2 = $frag_inst_to_seq->{$id_fib2}) or next;
        $contacts->{$id_sa2}->{$id_sb2}->{$id_contact}++;
        $contacts->{$id_sb2}->{$id_sa2}->{$id_contact}++;
        #print join("\t", 'CONTACT', $id_fia2, $id_fib2), "\n";
    }
    close($fh);

    return $contacts;
}

sub parse_queries {
    my($fn) = @_;

    my $fh;
    my $queries;

    defined($fh = myopen($fn)) or return undef;
    $queries = {};
    while(<$fh>) {
        while(/(\S+)/g) {
            $queries->{$1}++;
        }
    }
    close($fh);

    return $queries;
}


sub myopen {
    my($fn) = @_;

    my $fh;

    if($fn =~ /\.gz\Z/) {
        if(!open($fh, "zcat $fn |")) {
            warn "Error: myopen: cannot open pipe from 'zcat $fn'.";
            $fh = undef;
        }
    }
    else {
        if(!open($fh, $fn)) {
            warn "Error: myopen: cannot open '$fn' file for reading.";
            $fh = undef;
        }
    }

    return $fh;
}

