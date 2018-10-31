package Fist::NonDB::Seqs;

use strict;
use warnings;
use Moose;
use File::Path qw(make_path);
use Fist::Utils::Table;
use Fist::Utils::Web;
use Fist::NonDB::Network;
use Fist::Interface::Seq;

=head1 NAME

 Fist::NonDB::Seqs

=cut

=head1 ACCESSORS

=cut

has 'seqs' => (is => 'rw', isa => 'ArrayRef[Fist::Interface::Seq]', default => sub {return []}, auto_deref => 1);

=head1 METHODS

=cut

=head2 n_seqs

=cut

sub n_seqs {
    my($self) = @_;

    return scalar @{$self->{seqs}};
}

=head2 add_new

=cut

sub add_new {
    my($self, @seqs) = @_;

    push @{$self->seqs}, @seqs;
}

=head2 mechismo

 usage   :
 function:
 args    :
 returns :

=cut

sub mechismo {
    my($self, $results_type, $schema, $dn_search, $id_search, $json, $mat_ss, $mat_conf, $mat_prot_chem_class, $all_ppis, $all_structs) = @_;

    my $seq;
    my $id_seq_a1;
    my $prot_count_categories;
    my $site_count_categories;
    my $all_aliases;
    my $aliases;
    my $seq_a1;
    my $alias;
    my $pos_a1;
    my $site;
    my $acc_site;
    my $category;
    my $id_row_ppi;
    my $id_row_pci;
    my $id_row_pdi;
    my $id_row_struct;
    my $key;
    my $counts;
    my $per_search;
    my $per_seq;
    my $dn_out;
    my $fn_out;
    my $network_site_counts;
    my $source;
    my $ac_src;

    # Should I also store the residue-residue contacts, or are they easy enough
    # to get again? If I store them I can also store their individual IE values,
    # i.e. not just the sum for all the contacts that the site makes.

    $prot_count_categories = ['given', 'missing', 'unique', 'mismatch', 'disordered', 'structure', 'ppi_site', 'pci_site', 'pdi_site'];
    $site_count_categories = ['given', 'missing', 'unique', 'mismatch', 'disordered', 'structure', 'ppi_site', 'pci_site', 'pdi_site'];

    $per_search = {
                   network      => Fist::NonDB::Network->new(n_ids => $self->n_seqs, n_ids_max => 2000),
                   prot_table   => Fist::Utils::Table->new(column_names => [qw(id_seq name primary_id user_input taxa description nSites nMismatch minB62 maxB62 nDi nS nP nC nD maxNegativeIE maxPositiveIE mechScore)]),
                   prot_counts  => prot_counts_new(),
                   site_table   => Fist::Utils::Table->new(column_names => [qw(id_seq name primary_id pos_a1 res1_a1 res2_a1 site user_input mismatch blosum62 disordered structure nP ppis nC pcis pdis mechProt mechChem mechDNA mechScore)]),
                   site_counts  => site_counts_new(),
                  };

    $all_aliases = [];

    $network_site_counts = {};
    foreach $seq ($self->seqs) {
        $id_seq_a1 = $seq->id;
        $network_site_counts->{$id_seq_a1} = {on => {}, out => {}, in => {}};
    }

    foreach $seq ($self->seqs) {
        Fist::Interface::Seq::json_add_seq($json, $seq->id, $seq->name, $seq->primary_id, $seq->description, 'query', $results_type);
    }

    foreach $seq ($self->seqs) {
        $id_seq_a1 = $seq->id;

        $per_seq = {
                    site_info    => $seq->initialise_site_info($json),
                    network      => Fist::NonDB::Network->new(n_ids => 1),
                    prot_table   => Fist::Utils::Table->new(column_names => [qw(id_seq name primary_id user_input taxa description nSites nMismatch minB62 maxB62 nDi nS nP nC nD maxNegativeIE maxPositiveIE mechScore)]),
                    prot_counts  => prot_counts_new(),
                    site_table   => Fist::Utils::Table->new(column_names => [qw(id_seq name primary_id pos_a1 res1_a1 res2_a1 site user_input mismatch blosum62 disordered structure nP ppis nC pcis pdis mechProt mechChem mechDNA mechScore)]),
                    site_counts  => site_counts_new(),
                    ppi_table    => Fist::Utils::Table->new(column_names => [qw(id_ch id_seq_a1 name_a1 primary_id_a1 pos_a1 site start_a1 end_a1 id_seq_b1 name_b1 primary_id_b1 start_b1 end_b1 intev idcode pdb_desc homo pcid e_value conf ie ie_class sswitch)]),
                    pci_table    => Fist::Utils::Table->new(column_names => [qw(id_fh id_seq_a1 name_a1 primary_id_a1 pos_a1 site start_a1 end_a1 id_seq_a2 start_a2 end_a2 type_chem id_chem idcode pdb_desc pcid e_value conf ie ie_class)]),
                    pdi_table    => Fist::Utils::Table->new(column_names => [qw(id_fh id_seq_a1 name_a1 primary_id_a1 pos_a1 site start_a1 end_a1 id_seq_a2 start_a2 end_a2 idcode pdb_desc pcid e_value conf ie ie_class)]),
                    struct_table => Fist::Utils::Table->new(column_names => [qw(id_fh id_seq_a1 name_a1 primary_id_a1 pos_a1 site start_a1 end_a1 id_seq_a2 start_a2 end_a2 idcode pdb_desc pcid e_value)]),
                   };

        # initialise the sites' info from the search text
        foreach $pos_a1 (keys %{$per_seq->{site_info}->{sites}}) {
            foreach $site (@{$per_seq->{site_info}->{sites}->{$pos_a1}->{sites}}) {
                $network_site_counts->{$id_seq_a1}->{on}->{$site->{id}}++;
            }
        }

        # get the structural info for the sites
        $seq->structs($schema, $json, $results_type, $all_structs, $per_seq->{site_info});
        $seq->ppis_known($schema, $json, $results_type);
        $seq->process_contact_hits($schema, $json, $mat_ss, $mat_prot_chem_class, $mat_conf, $results_type, $per_seq->{site_info});

        # now make the tables, counts and network
        $id_row_ppi = -1;
        $id_row_pci = -1;
        $id_row_pdi = -1;
        $id_row_struct = -1;

        $seq->d3_network($json, [$per_search->{network}, $per_seq->{network}], $results_type, $network_site_counts, $per_seq->{site_info});

        $aliases = defined($json->{results}->{search}->{seqs_to_aliases}->{$id_seq_a1}) ? [sort keys %{$json->{results}->{search}->{seqs_to_aliases}->{$id_seq_a1}}] : [$seq->primary_id];
        push @{$all_aliases}, $aliases;
        $seq->prot_and_site_tables(
                                   $schema,
                                   $json,
                                   [
                                    $per_search->{prot_table},
                                    $per_seq->{prot_table},
                                   ],
                                   [
                                    $per_search->{prot_counts},
                                    $per_seq->{prot_counts},
                                   ],
                                   [
                                    $per_search->{site_table},
                                    $per_seq->{site_table},
                                   ],
                                   [
                                    $per_search->{site_counts},
                                    $per_seq->{site_counts},
                                   ],
                                   $results_type,
                                   $all_ppis,
                                   $per_seq->{site_info},
                                  );

        $seq->ppi_table($json, $per_seq->{ppi_table}, \$id_row_ppi, $results_type, $per_seq->{site_info});
        $seq->pci_table($json, $per_seq->{pci_table}, \$id_row_pci, $results_type, $per_seq->{site_info});
        $seq->pdi_table($json, $per_seq->{pdi_table}, \$id_row_pdi, $results_type, $per_seq->{site_info});
        $seq->struct_table($json, $per_seq->{struct_table}, \$id_row_struct, $results_type, $per_seq->{site_info});

        _finalise_results($json, $per_seq, $aliases, $site_count_categories, $prot_count_categories, $network_site_counts);

        # FIXME - per-seq networks can not be finalised until all sequences have been processed,
        # because don't know node site counts until then

        if($results_type eq 'search') {
            $dn_out = join '', $id_search, '/', $id_seq_a1, '.', $seq->primary_id, '/';
            make_path("$dn_search$dn_out");
            foreach $key (keys %{$per_seq}) {
                $fn_out = join '', $dn_out, join('.', $id_search, $id_seq_a1, $seq->primary_id, $key, 'json.gz');
                Fist::Utils::Search::write_json_file("$dn_search$fn_out", $per_seq->{$key}) or warn("Error: cannot open '$dn_search$fn_out' file for writing.");
                $per_seq->{$key} = "FILE:${fn_out}";
            }
        }

        # delete data that are no longer required.
        foreach $key (keys %{$json->{temporary}}) {
            $json->{temporary}->{$key} = undef;
        }

        # FIXME - also delete data stored per site?
    }
    foreach $key (keys %{$json->{results}->{$results_type}->{counts}}) {
        $json->{results}->{$results_type}->{counts}->{$key} = scalar keys %{$json->{results}->{$results_type}->{counts}->{$key}};
    }

    defined($json->{seq}) or ($all_aliases = [sort keys %{$json->{temporary_search}->{aliases}}]);
    _finalise_results($json, $per_search, $all_aliases, $site_count_categories, $prot_count_categories, $network_site_counts);

    return($per_search, $per_seq);
}

sub _finalise_results {
    my($json, $data, $aliases, $site_count_categories, $prot_count_categories, $network_site_counts) = @_;

    my $alias;
    my $pos_a1;
    my $site;
    my $acc_site;
    my $counts;
    my $category;
    my $barchart;
    my $id_seq_a1;
    my $node_a1;
    my $n_sites_on;
    my $n_sites_out;
    my $n_sites_in;

    foreach $alias (@{$aliases}) {
        $data->{prot_counts}->{given}->{n}->{$alias}++;

        if(keys(%{$json->{temporary_search}->{aliases}->{$alias}->{ids_seqs}}) == 0) {
            $data->{prot_counts}->{missing}->{n}->{$alias}++;
            $data->{prot_table}->add_row($alias);
            $data->{prot_table}->element($alias, 'user_input', $alias);

            foreach $pos_a1 (keys %{$json->{temporary_search}->{aliases}->{$alias}->{posns}}) {
                foreach $site (@{$json->{temporary_search}->{aliases}->{$alias}->{posns}->{$pos_a1}}) {
                    $acc_site = sprintf "%s/%s %s", $alias, $pos_a1, $site->{label_orig};
                    $data->{site_counts}->{missing}->{n}->{$acc_site}++;
                    if(!defined($data->{site_table}->get_row($acc_site))) {
                        $data->{site_table}->add_row($acc_site);
                        $data->{site_table}->element($acc_site, 'user_input', $acc_site);
                    }
                }
            }
        }
        else {
            foreach $pos_a1 (keys %{$json->{temporary_search}->{aliases}->{$alias}->{posns}}) {
                foreach $site (@{$json->{temporary_search}->{aliases}->{$alias}->{posns}->{$pos_a1}}) {
                    $acc_site = sprintf "%s/%s %s", $alias, $pos_a1, $site->{label_orig};
                    $data->{site_counts}->{given}->{n}->{$acc_site}++;
                }
            }
        }
    }

    # convert hashes to counts
    foreach $counts ($data->{site_counts}, $data->{prot_counts}) {
        foreach $category (keys %{$counts}) {
            $counts->{$category}->{n} = scalar keys %{$counts->{$category}->{n}};
        }
    }

    # convert hashes of sites to d3 barchart data
    $barchart = [];
    foreach $category (@{$site_count_categories}) {
        push @{$barchart}, $data->{site_counts}->{$category};
    }
    $data->{site_counts} = $barchart;

    $barchart = [];
    foreach $category (@{$prot_count_categories}) {
        push @{$barchart}, $data->{prot_counts}->{$category};
    }
    $data->{prot_counts} = $barchart;

    # get the number of sites on each node, and on edges out from and in to the node
    foreach $id_seq_a1 (keys %{$network_site_counts}) {
        if(defined($node_a1 = $data->{network}->get_node($id_seq_a1))) {
            if(defined($network_site_counts->{$id_seq_a1})) {
                $n_sites_on  = defined($network_site_counts->{$id_seq_a1}->{on})  ? scalar(keys(%{$network_site_counts->{$id_seq_a1}->{on}}))  : 0;
                $n_sites_out = defined($network_site_counts->{$id_seq_a1}->{out}) ? scalar(keys(%{$network_site_counts->{$id_seq_a1}->{out}})) : 0;
                $n_sites_in  = defined($network_site_counts->{$id_seq_a1}->{in})  ? scalar(keys(%{$network_site_counts->{$id_seq_a1}->{in}}))  : 0;
                $node_a1->n_sites_on($n_sites_on);
                $node_a1->n_sites_out($n_sites_out);
                $node_a1->n_sites_in($n_sites_in);
            }
        }
    }
    $data->{network}->finalise;

    return 1;
}

sub prot_counts_new {
    my $counts;

    $counts = {
               given      => {name => 'Given',         n => {}, description => 'Number of protein aliases given'},
               missing    => {name => 'Seq not found', n => {}, description => 'Number of aliases for which a sequence was not found'},
               unique     => {name => 'Unique seqs',   n => {}, description => 'Number of sequences found using the given aliases'},
               mismatch   => {name => 'Different AA',  n => {}, description => 'Number of sequences for which at least one site has a different wild-type amino-acid to the one given'},
               disordered => {name => 'Disordered',    n => {}, description => 'Number of sequences for which at least one site is in a disordered region'},
               structure  => {name => 'Structure',     n => {}, description => 'Number of sequences for which at least one site is in a region matched to a structure'},

               # ppi      = num proteins for which a prot-prot int was found
               # ppi_site = num proteins for which a prot-prot int was found with a site in the interface

               ppi        => {name => 'Prot-prot',       n => {}},
               ppi_site   => {name => 'Prot-prot sites', n => {}},

               pci        => {name => 'Prot-chem',       n => {}},
               pci_site   => {name => 'Prot-chem sites', n => {}},

               pdi        => {name => 'Prot-DNA/RNA',       n => {}},
               pdi_site   => {name => 'Prot-DNA/RNA sites', n => {}},
              };

    return $counts;
}

sub site_counts_new {
    my $counts;

    $counts = {
               given      => {name => 'Given',         n => {}},
               missing    => {name => 'Seq not found', n => {}},
               unique     => {name => 'Unique pos',    n => {}},
               mismatch   => {name => 'Different AA',  n => {}},
               disordered => {name => 'Disordered',    n => {}},
               structure  => {name => 'Structure',     n => {}},
               ppi_site   => {name => 'Prot-prot',     n => {}},
               pci_site   => {name => 'Prot-chem',     n => {}},
               pdi_site   => {name => 'Prot-DNA/RNA',  n => {}},
              };

    return $counts;
}

=head1 ROLES

 with 'Fist::Interface::Seqs';

=cut

with 'Fist::Interface::Seqs';

__PACKAGE__->meta->make_immutable;
1;
