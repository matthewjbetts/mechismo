package Fist::Utils::Search;

use Moose;
use JSON::Any;
use Dir::Self;
use String::Escape qw(printable);
use Fist::NonDB::Seqs;
use Fist::Utils::SubstitutionMatrix;
use Fist::Utils::Confidence;
use Fist::Utils::Overlap;
use HTML::Entities;
use namespace::autoclean;

=head1 PACKAGE VARIABLES

=cut

my $colours = {A2 => '00FFFF', B2 => 'FF00FF'};

# FIXME - better way of given path to static files? in config file maybe?
# FIXME - move all these to Fist::Interface::Seq ?
my $mat_ss = Fist::Utils::SubstitutionMatrix->new(fn => __DIR__ . '/../../../root/static/data/matrices/ss_mat_rbr_2014-07-30.dat', format => 'interprets');
my $mat_prot_chem_class = Fist::Utils::SubstitutionMatrix->new(fn => __DIR__ . '/../../../root/static/data/matrices/prot_chem_class_2014-03-06.txt', format => 'prot_chem_class');
my $mat_conf = Fist::Utils::Confidence->new(fn =>  __DIR__ . '/../../../root/static/data/matrices/fpr.txt');

=head1 NAME

Fist::Utils::Search

=head1 DESCRIPTION

[enter your description here]

=cut


=head1 ACCESSORS

=cut

has 'config' => (is => 'ro', isa => 'Any');

=head1 METHODS

=head2 search_text

=cut

sub search_by_text {
    my($self, $schema, $path, $params, $memory, $all_ppis, $all_structs) = @_;

    my $text;
    my $json_encoder;
    my $json;
    my $json_str;
    my $fn_search;
    my $fh_search;
    my $id_taxon;
    my $alias;
    my $pos_str;
    my $res;
    my $pos;
    my $label_orig;
    my $label;
    my $seqs_hash;
    my @my_seqs;
    my $seq;
    my $id_seq_a1;
    my $frag;
    my $frag_hit;
    my $contact_hit;
    my $url;
    my $res2;
    my $pos_a1;
    my $pos_b1;
    my $n_ss;
    my $row;
    my $res_b1;
    my $interprets_delta;
    my $site_query;
    my $site;
    my $seqs;
    my $results;
    my $per_search;
    my $per_seq;
    my $key1;
    my $key2;
    my $value1;
    my $value2;
    my $dn_search;
    my $id_search;
    my $fn_in;
    my $fn_out;
    my $ref;

    $dn_search = ($params->{dn_search} =~ /\/\Z/) ? $params->{dn_search} : $params->{dn_search} . '/';
    $id_search = $params->{id_search};

    # construct json from database queries
    $json = undef;
    $seqs_hash = {};
    if(defined($text = $params->{search})) {
        $json = $self->json_new($path, $params);

        # parse thresholds, sequence aliases and sites from the search parameters and then the search text
        parse_search_text($schema, $json, $text);

        # for each alias, find the relevant sequences
        foreach $alias (sort keys %{$json->{temporary_search}->{aliases}}) {
            if(@{$json->{temporary_search}->{aliases}->{$alias}->{ids_taxa}} > 0) {
                @my_seqs = $schema->resultset('Seq')->search(
                                                             {
                                                              'aliases.alias'          => $alias,
                                                              'seq_to_taxons.id_taxon' => {in => $json->{temporary_search}->{aliases}->{$alias}->{ids_taxa}},
                                                             },
                                                             {
                                                              join => [
                                                                       'aliases',
                                                                       'seq_to_taxons',
                                                                      ]
                                                             },
                                                            )->all;
            }
            else {
                @my_seqs = $schema->resultset('Seq')->search({'aliases.alias' => $alias}, { join => 'aliases'})->all;
            }

            if(@my_seqs > 0) {
                foreach $seq (@my_seqs) {
                    $id_seq_a1 = $seq->id;
                    $seqs_hash->{$id_seq_a1} = $seq;
                    $json->{temporary_search}->{aliases}->{$alias}->{ids_seqs}->{$id_seq_a1}++;
                    $json->{results}->{search}->{seqs_to_aliases}->{$seq->id}->{$alias}++;
                }
            }
        }
        $seqs = Fist::NonDB::Seqs->new();
        $seqs->add_new(sort {$a->id <=> $b->id} values %{$seqs_hash}); # ordering the seqs by id can give better db access later, especially for partitioned tables

        ($per_search, $per_seq) = $seqs->mechismo('search', $schema, $dn_search, $id_search, $json, $mat_ss, $mat_conf, $mat_prot_chem_class, $all_ppis, $all_structs);

        if($memory) {
            require Devel::Size;
            $Devel::Size::warn = 0;
            $Devel::Size::warn = 0; # 2nd time just to suppress 'used only once' warning

            my $g2b = 1024 ** 3;
            $results = {search => $per_search, thing => $per_seq};
            warn sprintf("%.02fG\t%s\t%s\n", Devel::Size::total_size($seqs) / $g2b, $seqs, 'seqs');
            warn sprintf("%.02fG\t%s\t%s\n", Devel::Size::total_size($results) / $g2b, $results, 'results');
            while(($key1, $value1) = each %{$results}) {
                while(($key2, $value2) = each %{$value1}) {
                    if(defined($value2)) {
                        warn sprintf("%.02fG\t\t%s\t%s\n", Devel::Size::total_size($value2) / $g2b, $value2, "results->{$key1}->{$key2}");
                    }
                    else {
                        warn sprintf("%.02fG\t\t%s\t%s\n", 0, 'undef', "results->{$key1}->{$key2}");
                    }
                }
            }
        }

        # output json files
        $key1 = 'search';
        $value1 = $per_search;
        while(($key2, $value2) = each %{$value1}) {
            if(defined($value2)) {
                $fn_out = join '', $id_search, '/', $id_search, '.', $key2, '.json.gz';
                Fist::Utils::Search::write_json_file("$dn_search$fn_out", $value2) or warn("Error: cannot open '$dn_search$fn_out' file for writing.");
                $json->{results}->{$key1}->{$key2} = "FILE:${fn_out}";
            }
        }

        # output site_table_tsv
        $fn_in = "${id_search}/${id_search}.site_table.json.gz";
        $fn_out = "${id_search}/${id_search}.site_table.tsv.gz";
        site_table_to_tsv("$dn_search$fn_in", "$dn_search$fn_out");
        $json->{results}->{search}->{site_table_tsv} = "FILE:${fn_out}";

        # delete temporary search results
        $json->{temporary_search} = undef;
        delete $json->{temporary_search};
    }

    return $json;
}

sub parse_search_text {
    my($schema, $json, $text) = @_;

    my $line;
    my $ids_taxa;
    my $id_taxon;
    my $taxon;
    my $alias;
    my $pos_str;
    my $label_orig;
    my $res;
    my $pos;
    my $label;
    my $res2;

    $ids_taxa = [];
    if(defined($json->{params}->{processed}->{taxa})) {
        foreach $id_taxon (sort {$a <=> $b} keys %{$json->{params}->{processed}->{taxa}}) {
            push @{$ids_taxa}, $id_taxon;
            $taxon = $schema->resultset('Taxon')->find({id => $id_taxon});
            $json->{params}->{processed}->{taxa}->{$id_taxon} = $taxon;
        }
    }

    $ids_taxa = defined($json->{params}->{processed}->{taxa}) ? [sort {$a <=> $b} keys %{$json->{params}->{processed}->{taxa}}] : [];
    ($text = printable($text)) =~ s/\\t/ /g; # tabs are escaped by 'printable'
    foreach $line (split /\\[rn]/, $text) {
        if(($line =~ /\A\s*\Z/) or ($line =~ /\A#/)) {
            next;
        }
        elsif($line =~ /\A\s*search_name=(\S+)\s*\Z/) {
            $json->{params}->{processed}->{search_name} = $1;
        }
        elsif($line =~ /\A\s*taxon=([\d,]+)\s*\Z/) {
            $ids_taxa = $1;
            $ids_taxa = [split /,/, $ids_taxa];

            foreach $id_taxon (@{$ids_taxa}) {
                if(!defined($json->{params}->{processed}->{taxa}->{$id_taxon})) {
                    $taxon = $schema->resultset('Taxon')->find({id => $id_taxon});
                    $json->{params}->{processed}->{taxa}->{$id_taxon} = $taxon;
                }
            }
        }
        elsif($line =~ /\A\s*(min_pcid\S*?)=([\d\.]+)\s*\Z/) {
            $json->{params}->{processed}->{$1} = $2;
        }
        elsif($line =~ /\A\s*(known_min_string_score)=(\d+)\s*\Z/) {
            $json->{params}->{processed}->{$1} = $2;
        }
        else {
            ($alias, $label_orig) = split /[\s\/]+/, $line, 2;
            defined($json->{temporary_search}->{aliases}->{$alias}) or ($json->{temporary_search}->{aliases}->{$alias} = {
                                                                                                                          alias    => $alias,
                                                                                                                          posns    => {},
                                                                                                                          ids_taxa => $ids_taxa,
                                                                                                                          ids_seqs => {},
                                                                                                                         });

            if(defined($label_orig)) {
                ($res, $pos, $label, $res2) = parse_label($label_orig);
                #print "res = '$res', pos = '$pos', label = '$label', res2 = '$res2'\n";
                #warn "PARSE_LABEL: Search: res = '$res', pos = '$pos', label = '$label', res2 = '$res2'";
                if(defined($pos)) {
                    defined($json->{temporary_search}->{aliases}->{$alias}->{posns}->{$pos}) or ($json->{temporary_search}->{aliases}->{$alias}->{posns}->{$pos} = []);
                    push @{$json->{temporary_search}->{aliases}->{$alias}->{posns}->{$pos}}, {
                                                                                              res        => $res,
                                                                                              res2       => $res2,
                                                                                              label      => $label,
                                                                                              label_orig => $label_orig,
                                                                                             };
                }
            }
        }
        #print "\n";
    }

    $json->{results}->{search}->{n_seqs_given} = scalar keys %{$json->{temporary_search}->{aliases}};
    $json->{results}->{search}->{n_sites_given} = 0;
    foreach $alias (keys %{$json->{temporary_search}->{aliases}}) {
        foreach $pos (keys %{$json->{temporary_search}->{aliases}->{$alias}->{posns}}) {
            $json->{results}->{search}->{n_sites_given} += scalar(@{$json->{temporary_search}->{aliases}->{$alias}->{posns}->{$pos}});
        }
    }

    return 1;
}

sub read_json_file {
    my($fn) = @_;

    my $fh;
    my $json_str;
    my $json_encoder;
    my $json;

    if($fn eq '-') {
        open($fh, $fn) or return(undef);
    }
    elsif(-e $fn) {
        if(($fn =~ /\.gz\Z/) or ($fn =~ /\.Z\Z/)) {
            open($fh, "zcat $fn |") or return(undef);
        }
        elsif($fn =~ /\.bz2\Z/) {
            open($fh, "bzip2 -d -c $fn |") or return(undef);
        }
        else {
            open($fh, $fn) or return(undef);
        }
    }
    else {
        return undef;
    }

    $json_str = [];
    while(<$fh>) {
        push @{$json_str}, $_;
    }
    close($fh);
    $json_str = join '', @{$json_str};
    $json_encoder = JSON::Any->new();
    $json = $json_encoder->jsonToObj($json_str);
    undef $json_str;

    return $json;
}

sub write_json_file {
    my($fn, $json) = @_;

    my $fh;
    my $json_encoder;

    if($fn eq '-') {
        open($fh, "> $fn") or return(0);
    }
    elsif($fn =~ /\.gz\Z/) {
        open($fh, "| gzip > $fn") or return(0);
    }
    elsif($fn =~ /\.bz2\Z/) {
        open($fh, "| bzip2 -c > $fn") or return(0);
    }
    else {
        open($fh, "> $fn") or return(0);
    }

    defined($json) or Carp::cluck('$json undefined');

    if((ref($json) eq 'HASH') and defined($json->{temporary})) {
        $json->{temporary} = undef;
        delete $json->{temporary};
    }

    $json_encoder = JSON::Any->new(convert_blessed => 1);
    print $fh $json_encoder->encode($json);
    close($fh);

    return 1;
}

=head2 copy_sites_from_search

=cut

sub copy_sites_from_search {
    my($json, $params, $suffix, $seq, $id_fh, $type_chem, $id_chem, $id_ch) = @_;

    my $dn_search;
    my $id_search;
    my $dn;
    my $fn;
    my $site_info;
    my $site_info2;
    my $posns_to_keep;
    my $pos;

    $dn_search = $json->{params}->{given}->{dn_search};
    $id_search = $json->{params}->{given}->{id_search};
    $dn = join '', $id_search, '/', $seq->id, '.', $seq->primary_id, '/';
    $fn = join '', $dn, join('.', $id_search, $seq->id, $seq->primary_id, 'site_info', 'json.gz');
    $site_info = read_json_file("$dn_search$fn");

    # if site info is given in the cgi parameters, remove all sites not listed in cgi params
    # FIXME - what about new sites? currently ignoring them
    $posns_to_keep = undef;
    if(defined($site_info2 = $seq->get_site_info_from_params($json, $params, $suffix))) {
        $posns_to_keep = $site_info2->{sites};
    }
    elsif(defined($id_fh) and defined($type_chem) and defined($id_chem)) {
        foreach $pos (keys %{$site_info->{fh_to_interface_sites}->{$id_fh}->{$type_chem}->{$id_chem}}) {
            $posns_to_keep->{$pos}++;
        }
    }
    elsif(defined($id_ch)) {
        $posns_to_keep = {};
        foreach $pos (keys %{$site_info->{ch_to_interface_sites}->{$id_ch}}) {
            $posns_to_keep->{$pos}++;
        }
    }

    if(defined($posns_to_keep)) { # otherwise keep them all
        foreach $pos (keys %{$site_info->{sites}}) {
            if(!defined($posns_to_keep->{$pos})) {
                $site_info->{sites}->{$pos} = undef;
                delete $site_info->{sites}->{$pos};
            }
        }
    }

    $json->{posns_to_keep} = $posns_to_keep;
    $json->{results}->{thing}->{sites}->{$seq->id} = $site_info->{sites};
    $json->{results}->{thing}->{fh_to_interface_sites}->{$seq->id} = $site_info->{fh_to_interface_sites};
    $json->{results}->{thing}->{ch_to_interface_sites}->{$seq->id} = $site_info->{ch_to_interface_sites};
}

=head2 seq_by_id

=cut

sub seq_by_id {
    my($self, $schema, $path, $params, $id_seq, $json) = @_;

    my $seqs;
    my $seq;
    my $per_search;
    my $per_seq;
    my $key;
    my $value;
    my $ref;
    my $dn;
    my $fn;
    my $dn_search;
    my $id_search;

    if(defined($seq = $schema->resultset('Seq')->find({id => $id_seq}))) {
        defined($json) or ($json = $self->json_new($path, $params));
        json_initialise_results_thing($json);
        $json->{results}->{thing}->{seq} = $seq;
        copy_sites_from_search($json, $params, '_a1', $seq);
        $dn_search = $json->{params}->{given}->{dn_search};
        $id_search = $json->{params}->{given}->{id_search};

        if(defined($json->{results}->{search}->{query_seqs}->{$id_seq})) {
            $dn = join '', $id_search, '/', $seq->id, '.', $seq->primary_id, '/';
            foreach $key (qw(network prot_table prot_counts site_table site_counts ppi_table pci_table pdi_table struct_table)) {
                $fn = join '', $dn, join('.', $id_search, $seq->id, $seq->primary_id, $key, 'json.gz');
                $json->{results}->{thing}->{$key} = $self->process_table($key, $id_search, $dn_search, $fn);
                #$json->{results}->{thing}->{$key} = "$dn_search$fn"; # for debugging

                # NOTE: reading the file here rather than just passing on the file name
                # to be read by javascript so that non-search can use the same seq.tt
                # template without having to write results to files.
            }
        }
        else {
            $seqs = Fist::NonDB::Seqs->new();
            $seqs->add_new($seq);
            ($per_search, $per_seq) = $seqs->mechismo('thing', $schema, $dn_search, $id_search, $json, $mat_ss, $mat_conf, $mat_prot_chem_class);
            while(($key, $value) = each %{$per_seq}) {
                $ref = ref $value;
                if($ref eq 'Fist::Utils::Table') {
                    $value = $value->array_ref;
                    $value = $self->process_table($key, $id_search, $dn_search, undef, $value);
                }
                $json->{results}->{thing}->{$key} = $value;
            }
        }
    }

    return $json;
}

=head2 frag_hit

=cut

sub frag_hit {
    my($self, $schema, $path, $params, $json) = @_;

    my $id_seq1;
    my $start1;
    my $end1;
    my $id_seq2;
    my $start2;
    my $end2;
    my $hsp;
    my $seq1;
    my $posns_a1;
    my $id_fh;
    my $type_chem;
    my $id_chem;
    my $pos;

    # Note: a FragHit is a just a preselected Hsp, mostly for storing the best set of
    # fragments matches to a sequence. So, am selecting from the Hsp table here, but
    # naming the subroutine 'frag_hit' to distinguish from other possible hsp-related
    # methods. FIXME - there might be a way of organising things that makes this implicit

    $id_seq1 = $params->{id_seq1};
    $start1 = $params->{start1};
    $end1 = $params->{end1};
    $id_seq2 = $params->{id_seq2};
    $start2 = $params->{start2};
    $end2 = $params->{end2};

    if(defined($json)) {
        json_initialise_results_thing($json);
    }
    else {
        $json = $self->json_new($path, $params);
    }

    if(defined($params->{type_chem}) and defined($params->{id_chem}) and defined($params->{id_fh})) {
        $json->{results}->{thing}->{type_chem} = $params->{type_chem};
        $json->{results}->{thing}->{id_chem}   = $params->{id_chem};
        $json->{results}->{thing}->{id_fh}     = $params->{id_fh};

        # FIXME - at the moment FragHits don't really have an id, it's just
        # set for each FragHit / HSP found in a search. Would be better to
        # give them an id in the database table.
    }

    if(defined($id_seq1) and defined($start1) and defined($end1) and defined($id_seq2) and defined($start2) and defined($end2)) {
        $hsp = $schema->resultset('Hsp')->find({id_seq1 => $id_seq1, start1 => $start1, end1 => $end1, id_seq2 => $id_seq2, start2 => $start2, end2 => $end2});
        $json->{results}->{thing}->{frag_hit} = $hsp;

        $seq1 = $schema->resultset('Seq')->find({id => $id_seq1});
        if(defined($params->{sites}) and ($params->{sites} = 'interface')) {
            copy_sites_from_search($json, $params, '_a1', $seq1, $params->{id_fh}, $params->{type_chem}, $params->{id_chem});
        }
        else {
            copy_sites_from_search($json, $params, '_a1', $seq1);
        }
    }

    return $json;
}

=head2 contact_hit_by_id

=cut

sub contact_hit_by_id {
    my($self, $schema, $path, $params, $id, $json) = @_;

    my $contact_hit;
    my $posns_a1;
    my $posns_b1;

    if(defined($json)) {
        json_initialise_results_thing($json);
    }
    else {
        $json = $self->json_new($path, $params);
    }

    if(defined($contact_hit = $schema->resultset('ContactHit')->find({id => $id}))) { # FIXME - prefetch contact and frag instances?
        $json->{results}->{thing}->{contact_hit} = $contact_hit;

        if(defined($params->{sites}) and ($params->{sites} = 'interface')) {
            copy_sites_from_search($json, $params, '_a1', $contact_hit->seq_a1, undef, undef, undef, $contact_hit->id);
            defined($contact_hit->seq_b1) and copy_sites_from_search($json, $params, '_b1', $contact_hit->seq_b1, undef, undef, undef, $contact_hit->id);
        }
        else {
            copy_sites_from_search($json, $params, '_a1', $contact_hit->seq_a1);
            defined($contact_hit->seq_b1) and copy_sites_from_search($json, $params, '_b1', $contact_hit->seq_b1);
        }
    }

    return $json;
}

=head2 contact_hits_by_ids

=cut

sub contact_hits_by_ids {
    my($self, $schema, $path, $params, $ids, $json) = @_;

    my $ch;

    if(defined($json)) {
        json_initialise_results_thing($json);
    }
    else {
        $json = $self->json_new($path, $params);
    }

    # FIXME - want to know the sites involved and their scores
    foreach $ch ($schema->resultset('ContactHit')->search({'me.id' => $ids})) { # FIXME - prefetch contacts etc?
    }

    return $json;
}

=head2 contact_hits_by_seqs

=cut


=head2 json_new

=cut

sub json_new {
    my($self, $path, $params) = @_;

    my $json;
    my $key;
    my $value;
    my $stringency;
    my $ids_taxa;
    my $id_taxon;
    my $extSite;
    my $source;
    my $ac_src;

    $json = {
             # params are stored here as given and also after they have been processed.
             # eg. the given parameter "stringency='high'" translates to different identities
             # and types of known interactions
             params                 => {
                                        given     => $params,
                                        processed => {search_name => undef, taxa => {}}, #  NOTE - other defaults taken from config
                                       },

             server_url             => undef,
             path                   => $path,

             # temporary results: those from which final info is generated.
             # Can/will be deleted after each seq has been processed.
             temporary              => {
                                        # structs
                                        frags                 => undef,
                                        frag_insts            => undef,
                                        frag_hits             => undef,
                                        frag_hit_info         => undef,
                                        seq_to_frag           => undef,
                                        pdbs                  => undef,

                                        # ppis_known
                                        known_ints            => undef,

                                        # ppis
                                        contact_hits          => undef,
                                        ppis                  => undef,

                                        # pcis and pdis
                                        pcis                  => undef,
                                        pdis                  => undef,
                                       },

             # results needed for the duration of a search but which can and will be deleted at the end of the search
             temporary_search      => {
                                       aliases => {},
                                      },

             # results provided to the user (i.e. used on pages)
             results                => {},
            };

    # get stringency and then set other parameters based on that using config info
    $stringency = defined($params->{stringency}) ? $params->{stringency} : $self->config->{params}->{stringency};
    $json->{params}->{processed}->{stringency} = $stringency;
    while(($key, $value) = each %{$self->config->{params}->{stringency_levels}->{$stringency}}) {
        $json->{params}->{processed}->{$key} = $value;
    }

    # process extSites
    (ref $params->{extSites} eq 'ARRAY') or ($params->{extSites} = [$params->{extSites}]); # is SCALAR if only one value was set...
    foreach $extSite (@{$params->{extSites}}) {
        defined($extSite) or next;
        ($extSite eq 'all') and next;
        ($source, $ac_src) = split /\|/, $extSite;
        $json->{params}->{processed}->{extSites}->{$source}->{$ac_src}++;
    }

    # ... which can then be overwritten by parameters in the URL / search form...
    foreach $key (qw(min_pcid min_pcid_homo min_pcid_hetero min_pcid_chem min_pcid_nuc min_pcid_known known_min_string_score)) {
        if(defined($params->{$key})) {
            #print join("\t", 'PARAMS', $key, $params->{$key}), "\n";
            $json->{params}->{processed}->{$key} = $params->{$key};
            $json->{params}->{processed}->{stringency} = 'custom';
        }
    }

    # the taxon may also be specified by the search form
    if(defined($params->{taxon}) and ($params->{taxon} ne '-1')) {
        $ids_taxa = [split /,/, $params->{taxon}];
        foreach $id_taxon (@{$ids_taxa}) {
            $json->{params}->{processed}->{taxa}->{$id_taxon}++;
        }
    }

    # Note: parameters can also be overwritten later by values given within the search text

    #warn join("\t", 'TAXA', 'json_new', sort {$a <=> $b} keys %{$json->{params}->{processed}->{taxa}});

    json_initialise_results_search($json);
    json_initialise_results_thing($json);

    # NOTE: all of these may be altered later by parameters given in the main search text

    #print join("\t", 'STRINGENCY', $json->{params}->{processed}->{stringency}), "\n";

    return $json;
}

=head2 json_initialise_results_search

=cut

sub json_initialise_results_search {
    my($json) = @_;

    # results of a search
    $json->{results}->{search} = {
                                  seqs                   => {},
                                  seqs_to_aliases        => {},

                                  n_seqs_given           => 0,
                                  n_sites_given          => 0,
                                  n_sites_from_elsewhere => 0,

                                  query_seqs             => {},
                                  id_frag_hit_max        => 0, # FIXME - no FragHit.id, so using this to fudge one
                                                               # FIXME - could be stored as per-search temporary data

                                  sites                  => {}, # keyed by seq->id then position
                                  network                => undef,
                                  prot_table             => undef,
                                  prot_counts            => undef,
                                  site_table             => undef,
                                  site_counts            => undef,
                                  counts                 => undef,
                                 };
}

=head2 json_initialise_results_thing

=cut

sub json_initialise_results_thing {
    my($json) = @_;

    # results for a particular seq, contact_hit or frag_hit
    $json->{results}->{thing} = {
                                 seq                    => undef, # used when getting a specific seq directly by id
                                 contact_hit            => undef,
                                 contact_hits           => [],
                                 frag_hit               => undef,
                                 type_chem              => undef,
                                 id_chem                => undef,
                                 id_fh                  => undef,

                                 network                => undef,
                                 prot_table             => undef,
                                 prot_counts            => undef,
                                 site_table             => undef,
                                 site_counts            => undef,
                                 counts                 => undef,

                                 # FIXME - could output these for whole searches too, but better
                                 # if I allow tables to be printed row-by-row first (to avoid
                                 # having to keep everything in memory until the end).
                                 ppi_table              => undef,
                                 pci_table              => undef,
                                 pdi_table              => undef,
                                 struct_table           => undef,
                                };
}


sub copy_site {
    my($seq, $pos, $site1, $site2) = @_;

    my $key1;

    defined($site2) or ($site2 = $seq->site_new($pos));
    foreach $key1 (keys %{$site1}) {
        $site2->{$key1} = $site1->{$key1};
    }

    return $site2;
}

=head2 parse_label

=cut

sub parse_label {
    my($label) = @_;

    my $res1;
    my $pos;
    my $res2;

    $| = 1;

    if($label =~ /\A([A-Z]{0,1})(\d*)(\S*)(\s*.*?)\s*\Z/) {
        # this allows for res2 = 'Sp' or 'Ka', for example
        # and also for res2 = '', ie. no change from res1
        ($res1, $pos, $res2, $label) = ($1, $2, $3, $4);
        ($pos eq '') and ($pos = undef);
        ($res2 eq '') and ($res2 = $res1);
        $label = $res2 . $label;
    }

    return($res1, $pos, $label, $res2);
}

=head2 get_hsp

=cut

sub get_hsp {
    my($hsps, $id_seq1, $start1, $end1, $id_seq2, $start2, $end2) = @_;

    return $hsps->{$id_seq1}->{$start1}->{$end1}->{$id_seq2}->{$start2}->{$end2};
}

=head2 add_hsp

=cut

sub add_hsp {
    my($hsps, $id_seq1, $start1, $end1, $id_seq2, $start2, $end2, $pcid, $e_value, $id_aln) = @_;

    my $hsp;

    if(!defined($hsp = get_hsp($hsps, $id_seq1, $start1, $end1, $id_seq2, $start2, $end2))) {
        $hsp = {pcid => $pcid, e_value => $e_value, id_aln => $id_aln};
        $hsps->{$id_seq1}->{$start1}->{$end1}->{$id_seq2}->{$start2}->{$end2} = $hsp;
    }

    return $hsp;
}


=head2 add_hsp_object

=cut

sub add_hsp_object {
    my($hsps, $id_seq1, $start1, $end1, $id_seq2, $start2, $end2, $hsp) = @_;

    $hsps->{$id_seq1}->{$start1}->{$end1}->{$id_seq2}->{$start2}->{$end2} = $hsp;
}

=head2 _get_rms

=cut

sub _get_rms {
    my($id_frag, $sth_rms) = @_;

    my $rms;
    my $table_rms;
    my $row_rms;

    # get the mapping of pdb residues to fist sequence positions
    $sth_rms->execute($id_frag);
    $table_rms = $sth_rms->fetchall_arrayref;
    $rms = {};
    foreach $row_rms (@{$table_rms}) {
        $rms->{$row_rms->[0]}->{$row_rms->[1]}->{$row_rms->[2]} = $row_rms->[3];
    }

    return $rms;
}

=head2 site_table_to_tsv

=cut

sub site_table_to_tsv {
    my($fn_in, $fn_out) = @_;

    my $str;
    my $fh_in;
    my $fh_out;
    my $encoder;
    my $json;
    my @headings;
    my $i;
    my %hash;
    my $general_info;
    my @interaction_info;
    my $ppi;
    my $rc;
    my $intEvLTP;
    my $intEvHTP;
    my $intEvStructure ;
    my $intev;
    my $pci;
    my $pdi;
    my $structure;
    my $n_info;
    my $name;

    if($fn_out =~ /\.gz\Z/) {
        if(!open($fh_out, "| gzip > $fn_out")) {
            warn "Error: cannot pipe to 'gzip > $fn_out'.";
            return 0;
        }
    }
    else {
        if(!open($fh_out, ">$fn_out")) {
            warn "Error: cannot open '$fn_out' file for writing.";
            return 0;
        }
    }

    if($fn_in =~ /\.gz\Z/) {
        if(!open($fh_in, "zcat $fn_in |")) {
            warn "Error: cannot open pipe from 'zcat $fn_in'.";
            return 0;
        }
    }
    else {
        if(!open($fh_in, $fn_in)) {
            warn "Error: cannot open '$fn_in' file for reading.";
            return 0;
        }
    }

    $str = [];
    while(<$fh_in>) {
        push @{$str}, $_;
    }
    $str = join '', @{$str};
    close($fh_in);

    $encoder = JSON::Any->new();
    $json = $encoder->jsonToObj($str);

    @headings = @{$json->[0]};

    # site_table headings:
    # --------------------
    # id_seq
    # name
    # primary_id
    # pos_a1
    # site
    # user_input
    # mismatch
    # blosum62
    # disordered
    # structure
    # nP
    # ppis
    # nC
    # pcis
    # pdis
    # mechProt
    # mechChem
    # mechDNA
    # mechScore

    print(
          $fh_out
          join(
               "\t",

               ## general info
               'name_a1',        # 00
               'primary_id_a1',  # 01
               'id_seq_a1',      # 02
               'pos_a1',         # 03
               'res_a1',         # 04
               'mut_a1',         # 05
               'user input',     # 06
               'mismatch',       # 07
               'blosum62',       # 08
               'iupred',         # 09
               'nS',             # 10
               'nP',             # 11
               'nC',             # 12
               'nD',             # 13
               'mechProt',       # 14
               'mechChem',       # 15
               'mechDNA/RNA',    # 16
               'mech',           # 17

               ## interaction info
               'name_b1',        # 18
               'primary_id_b1',  # 19
               'id_seq_b1',      # 20
               'dimer',          # 21

               'intEvLTP',       # 22
               'intEvHTP',       # 23
               'intEvStructure', # 24
               'intEv',          # 25
               'conf',           # 26
               'ie',             # 27
               'ie_class',       # 28
               'pos_b1',         # 29
               'res_b1',         # 30

               'id_hit',         # 31 - id_contact_hit or id_aln
               'idcode',         # 32
               'assembly',       # 33

               'pcid_a',         # 34
               'e_value_a',      # 35
               'model_a2',       # 36
               'pos_a2',         # 37
               'res_a2',         # 38
               'chain_a2',       # 39
               'resseq_a2',      # 40
               'icode_a2',       # 41

               'pcid_b',         # 42
               'e_value_b',      # 43
               'model_b2',       # 44
               'pos_b2',         # 45
               'res_b2',         # 46
               'chain_b2',       # 47
               'resseq_b2',      # 48
               'icode_b2',       # 49
              ),
          "\n",
         );

    for($i = 1; $i < @{$json}; $i++) {
        @hash{@headings} = @{$json->[$i]};
        $general_info = [
                         $hash{name},
                         $hash{primary_id},
                         $hash{id_seq},
                         $hash{pos_a1},
                         $hash{res1_a1},
                         $hash{res2_a1},
                         $hash{user_input},
                         ($hash{mismatch} eq '') ? 0 : 1,
                         $hash{blosum62},
                         ($hash{disordered} eq "") ? 0 : 1,
                         ($hash{structure} eq "") ? 0 : 1,
                         $hash{nP},
                         $hash{nC},
                         ($hash{pdis} eq "") ? 0 : 1,
                         $hash{mechProt},
                         $hash{mechChem},
                         $hash{mechDNA},
                         $hash{mechScore},
                        ];
        $n_info = 0;

        if(ref $hash{ppis} eq 'ARRAY') {
            foreach $ppi (@{$hash{ppis}}) {
                $name = $ppi->{name_b1};
                _ppi_info($ppi, $name, $encoder, \$n_info, $general_info, $fh_out);
            }
        }

        if(ref $hash{pcis} eq 'ARRAY') {
            foreach $pci (@{$hash{pcis}}) {
                $name = sprintf("[CHEM:%s:%s]", $pci->{type_chem}, $pci->{id_chem});
                _pci_info($pci, $name, $encoder, \$n_info, $general_info, $fh_out);
            }
        }

        if(ref $hash{pdis} eq 'ARRAY') {
            foreach $pdi (@{$hash{pdis}}) {
                $name = '[DNA/RNA]';
                _pci_info($pdi, $name, $encoder, \$n_info, $general_info, $fh_out);
            }
        }

        # structure matches
        if(ref $hash{structure} eq 'ARRAY') {
            foreach $structure (@{$hash{structure}}) {
                ++$n_info;
                @interaction_info = (
                                     '[PROT]',
                                     ('') x 12,
                                     $structure->{id_aln},
                                     $structure->{idcode},
                                     0,
                                     $structure->{pcid},
                                     $structure->{e_value},
                                     0,
                                     $structure->{pos_a2},
                                     $structure->{res_a2},
                                     $structure->{chain_a2},
                                     $structure->{resseq_a2},
                                     $structure->{icode_a2},

                                     ('') x 8,
                                    );
                print $fh_out join("\t", @{$general_info}, @interaction_info), "\n";
            }
        }

        # output the general info on its own if there are no ints or structures
        if($n_info == 0) {
            @interaction_info = ('') x 32;
            print $fh_out join("\t", @{$general_info}, @interaction_info), "\n";
        }
    }

    return 1;
}

sub _ppi_info {
    my($ppi, $name, $encoder, $n_info, $general_info, $fh_out) = @_;

    my @info;
    my $intEvLTP;
    my $intEvHTP;
    my $intEvStructure;
    my $intev;
    my $rc;

    ++${$n_info};
    $intEvLTP = 0;
    $intEvHTP = 0;
    $intEvStructure = 0;
    foreach $intev (@{$ppi->{intev}}) {
        if($intev->{method} eq 'structure') {
            $intEvStructure = 1;
        }

        if($intev->{htp}) {
            $intEvHTP = 1;
        }
        else {
            $intEvLTP = 1;
        }
    }

    foreach $rc (@{$ppi->{rc}}) {
        @info = (
                 $name,                              #  0
                 $ppi->{primary_id_b1},              #  1
                 $ppi->{id_seq_b1},                  #  2
                 ($ppi->{homo} ? 'homo' : 'hetero'), #  3

                 $intEvLTP,                          #  4
                 $intEvHTP,                          #  5
                 $intEvStructure,                    #  6
                 $encoder->encode($ppi->{intev}),    #  7

                 $ppi->{conf},                       #  8
                 $ppi->{ie},                         #  9
                 $ppi->{ie_class},                   # 10
                 $rc->{pos_b1},                      # 11
                 $rc->{res_b1},                      # 12

                 $ppi->{id_ch},                      # 13
                 $ppi->{idcode},                     # 14
                 $ppi->{assembly},                   # 15

                 $ppi->{pcid_a},                     # 16
                 $ppi->{e_value_a},                  # 17
                 $ppi->{model_a},                    # 18
                 $rc->{pos_a2},                      # 19
                 $rc->{res_a2},                      # 20
                 $rc->{chain_a2},                    # 21
                 $rc->{resseq_a2},                   # 22
                 $rc->{icode_a2},                    # 23

                 $ppi->{pcid_b},                     # 24
                 $ppi->{e_value_b},                  # 25
                 $ppi->{model_b},                    # 26
                 $rc->{pos_b2},                      # 27
                 $rc->{res_b2},                      # 28
                 $rc->{chain_b2},                    # 29
                 $rc->{resseq_b2},                   # 30
                 $rc->{icode_b2},                    # 31
                );
        print $fh_out join("\t", @{$general_info}, @info), "\n";
    }

    return 1;
}

sub _pci_info {
    my($pci, $name, $encoder, $n_info, $general_info, $fh_out) = @_;

    my $rc;
    my @info;

    ++${$n_info};
    foreach $rc (@{$pci->{rc}}) {
        @info = (
                 $name,    # 0
                 ('') x 7, # 1-7

                 $pci->{conf},                       #  8
                 $pci->{ie},                         #  9
                 $pci->{ie_class},                   # 10
                 $rc->{pos_b1},                      # 11
                 $rc->{res_b1},                      # 12

                 $pci->{id_ch},                      # 13
                 $pci->{idcode},                     # 14
                 $pci->{assembly},                   # 15

                 $pci->{pcid_a},                     # 16
                 $pci->{e_value_a},                  # 17
                 $pci->{model_a},                    # 18
                 $rc->{pos_a2},                      # 19
                 $rc->{res_a2},                      # 20
                 $rc->{chain_a2},                    # 21
                 $rc->{resseq_a2},                   # 22
                 $rc->{icode_a2},                    # 23

                 '',                                 # 24
                 '',                                 # 25
                 $pci->{model_b},                    # 26
                 $rc->{pos_b2},                      # 27
                 $rc->{res_b2},                      # 28
                 $rc->{chain_b2},                    # 29
                 $rc->{resseq_b2},                   # 30
                 $rc->{icode_b2},                    # 31
                );
        print $fh_out join("\t", @{$general_info}, @info), "\n";
    }

    return 1;
}

sub _pci_info_v1 {
    my($pci, $name) = @_;

    my @info;

    @info = (
             $name,
             ('') x 7,

             $pci->{conf},
             $pci->{ie},
             $pci->{ie_class},
             '',
             '',

             $pci->{id_aln},
             $pci->{idcode},
             0,

             $pci->{pcid},
             $pci->{e_value},
             0,
             $pci->{pos_a2},
             $pci->{res_a2},
             $pci->{chain_a2},
             $pci->{resseq_a2},
             $pci->{icode_a2},

             ('') x 8,
            );

    return @info;
}

sub process_table {
    my($self, $type, $id_search, $dn_search, $fn, $json) = @_;

    my $process;
    my $searchRoot;
    my $fnFull;
    my $jsonProcessed;
    my $headings;
    my $row;
    my $hash;

    if(defined($fn)) {
        $searchRoot = "/search/id/$id_search";
        $fnFull = join('', __DIR__, '/../../../', $dn_search, $fn); # FIXME - must be a better way of getting this...
        $json = read_json_file($fnFull);
    }

    if($type eq 'prot_table') {
        $process = sub {
            my($hash) = @_;

            my $mechScore;
            my $species;
            my $taxon;
            my $rowProcessed;

            $mechScore = sprintf "%.02f", ($hash->{mechScore} == '') ? 0 : $hash->{mechScore};
            $species = [];
            if($hash->{taxa} ne '') {
                foreach $taxon (@{$hash->{taxa}}) {
                    push @{$species}, $taxon->{scientific_name};
                }
            }
            $species = join ', ', @{$species};

            $rowProcessed = [
                             $hash->{id_seq},
                             sprintf("<a href='%s/seq/%s' target='_blank'>%s</a>", $searchRoot, $hash->{id_seq}, $hash->{name}), # protein_a1
                             $hash->{primary_id},
                             truncateString($hash->{user_input}, 27),
                             $species,
                             truncateString($hash->{description}, 27),
                             $hash->{nSites},
                             $hash->{nMismatch},
                             $hash->{minB62},
                             $hash->{maxB62},
                             $hash->{nDi},
                             $hash->{nS},
                             $hash->{nP},
                             $hash->{nC},
                             $hash->{nD},
                             $hash->{maxNegativeIE},
                             $hash->{maxPositiveIE},
                             $mechScore,
                            ];

            return $rowProcessed;
        };
    }
    elsif($type eq 'site_table') {
        $process = sub {
            my($hash) = @_;

            my $mechProt;
            my $mechChem;
            my $mechDNA;
            my $mechScore;
            my $rowProcessed;
            my $ppi_str;
            my $ppi;
            my $pci_str;
            my $pci;
            my $pdi_str;
            my $pdi;

            $mechProt  = sprintf "%.02f", ($hash->{mechProt}  eq '') ? 0 : $hash->{mechProt};
            $mechChem  = sprintf "%.02f", ($hash->{mechChem}  eq '') ? 0 : $hash->{mechChem};
            $mechDNA   = sprintf "%.02f", ($hash->{mechDNA}   eq '') ? 0 : $hash->{mechDNA};
            $mechScore = sprintf "%.02f", ($hash->{mechScore} eq '') ? 0 : $hash->{mechScore};

            # protein interactions
            $ppi_str = [];
            if($hash->{ppis} ne '') {
                foreach $ppi (@{$hash->{ppis}}) {
                    push @{$ppi_str}, ppiStr($searchRoot, $ppi, $hash->{pos_a1}, $hash->{site});
                }
            }
            $ppi_str = (@{$ppi_str} > 0) ? join('', '<ul><li>', join('</li><li>', @{$ppi_str}), '</li></ul>') : '';

            # chemical interactions
            $pci_str = [];
            if($hash->{pcis} ne '') {
                foreach $pci (@{$hash->{pcis}}) {
                    push @{$pci_str}, pciStr($searchRoot, $pci, $hash->{pos_a1}, $hash->{site});
                }
            }
            $pci_str = (@{$pci_str} > 0) ? join('', '<ul><li>', join('</li><li>', @{$pci_str}), '</li></ul>') : '';

            # DNA/RNA interactions
            $pdi_str = [];
            if($hash->{pdis} ne '') {
                foreach $pdi (@{$hash->{pdis}}) {
                    push @{$pdi_str}, pdiStr($searchRoot, $pdi, $hash->{pos_a1}, $hash->{site});
                }
            }
            $pdi_str = (@{$pdi_str} > 0) ? join('', '<ul><li>', join('</li><li>', @{$pdi_str}), '</li></ul>') : '';

            $rowProcessed = [
                             $hash->{id_seq},
                             sprintf("<a href='%s/seq/%s' target='_blank'>%s</a>", $searchRoot, $hash->{id_seq}, $hash->{name}), # protein_a1
                             $hash->{primary_id},
                             $hash->{site},
                             truncateString($hash->{user_input}, 27),
                             $hash->{mismatch},
                             $hash->{blosum62},
                             $hash->{disordered},
                             '', # structure
                             $hash->{nP},
                             $ppi_str,
                             $hash->{nC},
                             $pci_str,
                             $pdi_str,
                             $mechProt,
                             $mechChem,
                             $mechDNA,
                             $mechScore,
                            ];

            return $rowProcessed;
        };
    }
    elsif($type eq 'ppi_table') {
        $process = sub {
            my($hash) = @_;

            my $pcid;
            my $intEvStr;
            my $intEv;
            my $rowProcessed;

            $pcid = sprintf "%.0f", $hash->{pcid};

            $intEvStr = [];
            foreach $intEv (@{$hash->{intev}}) {
                push @{$intEvStr}, join('<li>', intEvStr($intEv), '</li>');
            }
            $intEvStr = (@{$intEvStr} > 0) ? join('', '<ul>', @{$intEvStr}, '</ul>') : '';

            $rowProcessed = [
                             $hash->{id_ch},
                             $hash->{id_seq_a1},
                             $hash->{name_a1},
                             $hash->{primary_id_a1},
                             join('', $hash->{site}, ' (', ppiTIA($searchRoot, $hash, $hash->{pos_a1}, $hash->{site}), ')'),
                             $hash->{start_a1},
                             $hash->{end_a1},
                             $hash->{id_seq_b1},
                             $hash->{name_b1},
                             $hash->{primary_id_b1},
                             sprintf("<a href='%s/seq/%s' target='_blank'>%s</a>", $searchRoot, $hash->{id_seq_b1}, $hash->{name_b1}),
                             $hash->{start_b1},
                             $hash->{end_b1},
                             $intEvStr,
                             templateHtml($hash->{idcode}, $hash->{pdb_desc}),
                             ($hash->{homo} == 1) ? 'homo' : 'hetero',
                             join(' ', $pcid, confHtml($pcid, $hash->{conf})),
                             sprintf("%.02e", $hash->{e_value}),
                             ($hash->{ie} eq '') ? '' : sprintf("%.02f %s", $hash->{ie}, ieClassHtml($hash->{ie}, $hash->{ie_class})),
                            ];

            return $rowProcessed;
        };
    }
    elsif($type eq 'pci_table') {
        $process = sub {
            my($hash) = @_;

            my $pcid;
            my $rowProcessed;

            $pcid = sprintf "%.0f", $hash->{pcid};

            $rowProcessed = [
                             $hash->{id_fh},
                             $hash->{id_seq_a1},
                             $hash->{name_a1},
                             $hash->{primary_id_a1},
                             join('', $hash->{site}, ' (', pciTIA($searchRoot, $hash, $hash->{pos_a1}, $hash->{site}), ')'),
                             $hash->{start_a1},
                             $hash->{end_a1},
                             templateHtml($hash->{idcode}, $hash->{pdb_desc}),
                             join(' ', $pcid, confHtml($pcid, $hash->{conf})),
                             sprintf("%.02e", $hash->{e_value}),
                             ($hash->{ie} eq '') ? '' : sprintf("%.02f %s", $hash->{ie}, ieClassHtml($hash->{ie}, $hash->{ie_class})),

                             # FIXME - include type_chem description
                             $hash->{type_chem},

                             # FIXME - include chemical description
                             sprintf("<a href='http://www.ebi.ac.uk/pdbe-srv/pdbechem/chemicalCompound/show/%s' target='_blank'>%s</a>", $hash->{id_chem}, $hash->{id_chem}),
                            ];

            return $rowProcessed;
        };
    }
    elsif($type eq 'pdi_table') {
        $process = sub {
            my($hash) = @_;

            my $pcid;
            my $rowProcessed;

            $pcid = sprintf "%.0f", $hash->{pcid};

            $rowProcessed = [
                             $hash->{id_fh},
                             $hash->{id_seq_a1},
                             $hash->{name_a1},
                             $hash->{primary_id_a1},
                             join('', $hash->{site}, ' (', pciTIA($searchRoot, $hash, $hash->{pos_a1}, $hash->{site}), ')'),
                             $hash->{start_a1},
                             $hash->{end_a1},
                             templateHtml($hash->{idcode}, $hash->{pdb_desc}),
                             join(' ', $pcid, confHtml($pcid, $hash->{conf})),
                             sprintf("%.02e", $hash->{e_value}),
                             ($hash->{ie} eq '') ? '' : sprintf("%.02f %s", $hash->{ie}, ieClassHtml($hash->{ie}, $hash->{ie_class})),
                            ];

            return $rowProcessed;
        };
    }
    elsif($type eq 'struct_table') {
        $process = sub {
            my($hash) = @_;

            my $pcid;
            my $rowProcessed;

            $pcid = sprintf "%.0f", $hash->{pcid};

            $rowProcessed = [
                             $hash->{id_fh},
                             $hash->{id_seq_a1},
                             $hash->{name_a1},
                             $hash->{primary_id_a1},
                             join('', $hash->{site}, ' (', structTIA($searchRoot, $hash, $hash->{pos_a1}, $hash->{site}), ')'),
                             $hash->{start_a1},
                             $hash->{end_a1},
                             templateHtml($hash->{idcode}, $hash->{pdb_desc}),
                             join(' ', $pcid, confHtml($pcid, $hash->{conf})),
                             sprintf("%.02e", $hash->{e_value}),
                            ];

            return $rowProcessed;
        };
    }

    if(defined($process)) {
        $jsonProcessed = [];
        $headings = $json->[0];
        foreach $row (@{$json}[1..$#{$json}]) {
            $hash = {};
            @{$hash}{@{$headings}} = @{$row};
            push @{$jsonProcessed}, $process->($hash);
        }

        return $jsonProcessed;
    }
    else {
        return $json;
    }
}

sub truncateString {
    my($string, $toLength) = @_;

    my $length;
    my $truncatedString;

    $length = length $string;
    $truncatedString = ($length > $toLength) ? (substr($string, 0, $toLength) . '...') : $string;

    return $truncatedString;
}

sub ppiStr {
    my($searchRoot, $ppi, $pos_a1, $site) = @_;

    my $pcid;
    my $ie;
    my $ppi_str;

    $pcid = sprintf "%.0f", $ppi->{pcid};
    $ie   = sprintf "%.2f", $ppi->{ie};

    $ppi_str = join(
                    '',
                    confHtml($pcid, $ppi->{conf}),
                    ' ',
                    ieClassHtml($ie, $ppi->{ie_class}),
                    ' ',
                    sprintf("<a href='%s/seq/%s' target='_blank'>%s</a>", $searchRoot, $ppi->{id_seq_b1}, $ppi->{name_b1}),
                    ' (',
                    ppiTIA($searchRoot, $ppi, $pos_a1, $site),
                    ')',
                   );

    return $ppi_str;
}

sub pciStr {
    my($searchRoot, $pci, $pos_a1, $site) = @_;

    my $pcid;
    my $ie;
    my $pci_str;

    $pcid = sprintf "%.0f", $pci->{pcid};
    $ie   = sprintf "%.2f", $pci->{ie};

    $pci_str = join(
                    '',
                    confHtml($pcid, $pci->{conf}),
                    ' ',
                    ieClassHtml($ie, $pci->{ie_class}),
                    ' ',
                    sprintf("<a href='http://www.ebi.ac.uk/pdbe-srv/pdbechem/chemicalCompound/show/%s' target='_blank'>%s</a>", $pci->{id_chem}, $pci->{type_chem}),
                    ' (',
                    pciTIA($searchRoot, $pci, $pos_a1, $site),
                    ')',
                   );

    return $pci_str;
}

sub pdiStr {
    my($searchRoot, $pdi, $pos_a1, $site) = @_;

    my $pcid;
    my $ie;
    my $pdi_str;

    $pcid = sprintf "%.0f", $pdi->{pcid};
    $ie   = sprintf "%.2f", $pdi->{ie};

    $pdi_str = join(
                    '',
                    confHtml($pcid, $pdi->{conf}),
                    ' ',
                    ieClassHtml($ie, $pdi->{ie_class}),
                    ' ',
                    ' (',
                    pciTIA($searchRoot, $pdi, $pos_a1, $site),
                    ')',
                   );

    return $pdi_str;
}

sub confHtml {
    my($pcid, $conf) = @_;

    my $conf_symbol;
    my $html;

    $conf_symbol = defined($conf) ? uc(substr($conf, 0, 1)) : '';
    $html = sprintf "<div class='%sConfidence' title='identity = %s%%, confidence=%s'>%s</div>", $conf, $pcid, $conf, $conf_symbol;

    return $html;
}


sub ieClassHtml {
    my($ie, $ie_class) = @_;

    my $ie_symbol = '';
    my $html;

    $ie_symbol = '';
    $html = '';

    if($ie ne '') {
        if($ie_class eq 'enabling') {
            $ie_symbol = 'E';
        }
        elsif($ie_class eq 'enablingWeak') {
            $ie_symbol = 'e';
        }
        elsif($ie_class eq 'disabling') {
            $ie_symbol = 'D';
        }
        elsif($ie_class eq 'disablingWeak') {
            $ie_symbol = 'd';
        }
        elsif($ie_class eq 'neutral') {
            $ie_symbol = 'N';
        }
        elsif($ie_class eq 'unknown') {
            $ie_symbol = 'U';
        }
        $html = sprintf "<div class='%sIE' title='Interaction Effect = %s (%s)'>%s</div>", $ie_class, $ie, $ie_class, $ie_symbol;
    }

    return $html;
}

sub ppiTIA {
    my($searchRoot, $ppi, $pos_a1, $site) = @_;

    my $url;
    my $ppiT;
    my $ppiI;
    my $ppiA;
    my $ppiTIA;

    $url = join('', $searchRoot, '/contact_hit/', $ppi->{id_ch});

    if($site eq '(none)') {
        $ppiT = '';
        $ppiI = '';
    }
    else {
        $ppiT = sprintf "<a href='%s?pos_a1=%d&label_a1=%s' target='_blank' title='3D interaction structure showing this site (%s)'>T</a>, ", $url, $pos_a1, $site, $site;
        $ppiI = sprintf "<a href='%s?sites=interface' target='_blank' title='3D interaction structure showing interface sites'>I</a>, ", $url;
    }
    $ppiA = sprintf "<a href='%s' target='_blank' title='3D interaction structure showing all sites'>A</a>", $url;

    $ppiTIA = join '', $ppiT, $ppiI, $ppiA;

    return $ppiTIA;
}

sub pciTIA {
    my($searchRoot, $ppi, $pos_a1, $site) = @_;

    my $url;
    my $ppiT;
    my $ppiI;
    my $ppiA;
    my $ppiTIA;

    $url = join('', $searchRoot, '/contact_hit/', $ppi->{id_ch});

    if($site eq '(none)') {
        $ppiT = '';
        $ppiI = '';
    }
    else {
        $ppiT = sprintf "<a href='%s?pos_a1=%d&label_a1=%s' target='_blank' title='3D interaction structure showing this site (%s)'>T</a>, ", $url, $pos_a1, $site, $site;
        $ppiI = sprintf "<a href='%s?sites=interface' target='_blank' title='3D interaction structure showing interface sites'>I</a>, ", $url;
    }
    $ppiA = sprintf "<a href='%s' target='_blank' title='3D interaction structure showing all sites'>A</a>", $url;

    $ppiTIA = join '', $ppiT, $ppiI, $ppiA;

    return $ppiTIA;
}

sub pciTIA_v1 {
    my($searchRoot, $pci, $pos_a1, $site) = @_;

    my $url;
    my $type_chem;
    my $id_chem;
    my $pciT;
    my $pciI;
    my $pciA;
    my $pciTIA;

    $type_chem = defined($pci->{type_chem}) ? $pci->{type_chem} : 'DNA/RNA';
    $id_chem = defined($pci->{id_chem}) ? $pci->{id_chem} : 'DNA/RNA';

    $url = join(
                '',
                $searchRoot,
                "/frag_hit?id_seq1=",
                $pci->{id_seq_a1},
                "&start1=",
                $pci->{start_a1},
                "&end1=",
                $pci->{end_a1},
                "&id_seq2=",
                $pci->{id_seq_a2},
                "&start2=",
                $pci->{start_a2},
                "&end2=",
                $pci->{end_a2},
                "&type_chem=",
                $type_chem,
                "&id_chem=",
                $id_chem,
                "&id_fh=",
                $pci->{id_fh},
               );

    if($site eq '(none)') {
        $pciT = '';
        $pciI = '';
    }
    else {
        $pciT = sprintf("<a href='%s&pos_a1=%d&label_a1=%s' target='_blank' title='single-protein structure showing this site (%s)'>T</a>, ", $url, $pos_a1, $site, $site);
        $pciI = sprintf("<a href='%s&sites=interface' target='_blank' title='single-protein structure showing interface sites'>I</a>, ", $url);
    }
    $pciA = sprintf("<a href='%s' target='_blank' title='single-protein structure showing all sites'>A</a>", $url);
    $pciTIA = join '', $pciT, $pciI, $pciA;

    return $pciTIA;
}

sub templateHtml {
    my($idcode, $title) = @_;

    my $html;

    $title = ($title eq '') ? $idcode : $title;

    $html = sprintf(
                    "<span title='%s'><a href='http://www.rcsb.org/pdb/explore/explore.do?structureId=%s' target='_blank'>%s</a>: %s</span>",
                    $title,
                    $idcode,
                    $idcode,
                    truncateString($title, 27),
                   );

    return $html;
}

sub intEvStr {
    my($intEv) = @_;

    my $intEvStr;
    my $info;

    if($intEv->{method} eq 'string') {
        $intEvStr = sprintf "<a href='http://current.string-db.org/cgi/set_evidence.pl?all_channels_on=1&data_channel=experimental&direct_neighbor=1&limit=0&show_all_direct=off&show_all_transferred=off&targetmode=proteins&identifier
s=%s%%250D%s' target='_blank'>STRING:%d</a>", $intEv->{idString1}, $intEv->{idString2}, $intEv->{score};
    }
    else {
        $intEvStr = ucfirst $intEv->{method};
    }

    return $intEvStr;
}

sub intEvStr_v01 {
    my($intEv) = @_;

    my $intEvStr;
    my $info;

    if($intEv->{pmid} == 0) {
        $intEvStr = $intEv->{method};
    }
    else {
        $info = [];
        push @{$info}, (($intEv->{htp} == 1) ? 'HTP' : 'LTP');
        ($intEv->{dp} == 1) and push(@{$info}, 'DP');
        ($intEv->{hq} == 1) and push(@{$info}, 'HQ');
        $info = join ', ', @{$info};

        $intEvStr = sprintf "<a href='http://www.ncbi.nlm.nih.gov/pubmed/%s' target='_blank'>%s</a> (%s)", $intEv->{pmid}, $intEv->{pmid}, $info;
    }

    return $intEvStr;
}

sub structTIA {
    my($searchRoot, $struct, $pos_a1, $site) = @_;

    my $url;
    my $structTIA;

    $url = join(
                '',
                $searchRoot,
                "/frag_hit?id_seq1=",
                $struct->{id_seq_a1},
                "&start1=",
                $struct->{start_a1},
                "&end1=",
                $struct->{end_a1},
                "&id_seq2=",
                $struct->{id_seq_a2},
                "&start2=",
                $struct->{start_a2},
                "&end2=",
                $struct->{end_a2}
               );

    $structTIA = join(
                      '',
                      sprintf("<a href='%s&pos_a1=%d&label_a1=%s' target='_blank' title='single-protein structure showing this site (%s)'>T</a>, ", $url, $pos_a1, $site, $site),
                      sprintf("<a href='%s' target='_blank' title='single-protein structure showing all sites)'>A</a>", $url),
                     );

    return $structTIA;
}

=head1 AUTHOR

Matthew Betts

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;

