package Fist::IO::Seq;

use Moose;
use Carp ();
use Bio::SeqIO;
use Fist::Utils::IdMapping;
use Fist::NonDB::Seq;
use Fist::NonDB::Alias;
use Fist::NonDB::Taxon;
use namespace::autoclean;

=head1 NAME

 Fist::IO::Seq

=cut

=head1 ROLES

 with 'Fist::IO';

=cut

with 'Fist::IO';

=head2 in

 usage   :
 function: get/set Bio::SeqIO object
 args    :
 returns :

=cut

has 'in' => (is => 'rw', isa => 'Bio::SeqIO');

=head1 METHODS

=cut

=head2 parse_uniprot

 usage   : while($seq = $self->parse_uniprot($features, 'trembl'){print $seq->id, "\n";}
 function: parse next sequence and it's taxon and all accessions and identifiers
           from swissprot-format uniprot files. Assign a new unique identifier.
 args    : - Fist::Interface::Features compliant object of Features for any FeatureInsts found
           - boolean indicating that the sequences are from trembl ('unreviewed'), otherwise sprot ('reviewed') assumed
 returns : a Fist::NonDB::Seq object

=cut

sub parse_uniprot {
    my($self, $features, $trembl) = @_;

    my $in;
    my $bioseq;
    my $ac;
    my $seq;
    my $alias;
    my $annotation_collection;
    my $taxon;
    my $annotation;
    my $node;
    my $child;
    my $name;
    my $source;
    my $biofeature;
    my $evidence;
    my $description;
    my $ac_src;
    my $feature;
    my $feature2;
    my $start;
    my $end;
    my $score;
    my $feature_inst;
    my $unrecognised_features;
    my $ignore_features = {HELIX => 1, STRAND => 1, TURN => 1};
    my $ref;
    my $rp;
    my $pmids;
    my $wt;
    my $mt;
    my $type;
    my $enzyme_str;
    my @enzymes;

    $source = defined($trembl) ? 'uniprot-trembl' : 'uniprot-sprot';

    if(!defined($in = $self->in)) {
        # UniProt changed their feature table format with release 2019_11,
        # breaking the bioperl parser...
        #
        # The bioperl embl parser can parse the new feature tables, but it
        # doesn't parse some of the other uniprot stuff, eg. GN (gene names);
        #
        # argh...
        #$in = Bio::SeqIO->new(-fh => $self->fh, -format => 'swiss');
        $in = Bio::SeqIO->new(-fh => $self->fh, -format => 'embl');
        $self->in($in);
    }

    $unrecognised_features = {};
    if($bioseq = $in->next_seq) {
        $seq = Fist::NonDB::Seq->new(
                                     seq           => $bioseq->seq,
                                     len           => $bioseq->length,
                                     chemical_type => 'peptide',
                                     source        => $source,
                                     description   => ($bioseq->description =~ /Full=(.*?);/) ? $1 : $bioseq->description,
                                    );

        # get gene names and related annotations
        $annotation_collection = $bioseq->annotation;
        foreach $annotation ($annotation_collection->get_Annotations('gene_name')) {
            foreach $node ($annotation->findnode('gene_name')) {
                foreach $child ($node->children) {
                    foreach $name ($child->children) {
                        $seq->name or $seq->name($name);
                        $alias = Fist::NonDB::Alias->new(seq => $seq, alias => $name, type => $child->element);
                        $seq->add_to_aliases($alias);
                    }
                }
            }
        }

        # add aliases to sequence object
        $alias = Fist::NonDB::Alias->new(seq => $seq, alias => $bioseq->id, type => 'UniProtKB ID');
        $seq->name or $seq->name($bioseq->id);
        $seq->add_to_aliases($alias);
        foreach $ac ($bioseq->accession, $bioseq->get_secondary_accessions) {
            $seq->primary_id or $seq->primary_id($ac);
            $seq->name or $seq->name($ac);
            $alias = Fist::NonDB::Alias->new(seq => $seq, alias => $ac, type => 'UniProtKB accession');
            $seq->add_to_aliases($alias);
        }

        # FIXME - get taxon from those already loaded (not essential
        # for now as only using for SeqToTaxon info).
        $taxon = Fist::NonDB::Taxon->new(id => $bioseq->species->ncbi_taxid);
        $seq->add_to_taxa($taxon);

        # get sequence feature instances
        foreach $biofeature ($bioseq->get_SeqFeatures) {
            #$description = $biofeature->has_tag('description') ? join(' ', $biofeature->get_tag_values('description')) : '';

            $pmids = {};
            if($biofeature->has_tag('evidence')) {
                $evidence = join(' ', $biofeature->get_tag_values('evidence'));
                while($evidence =~ /PubMed:(\d+)/g) {
                    $pmids->{$1}++;
                }
            }
            $pmids = [sort {$a <=> $b} keys %{$pmids}];

            $description = $biofeature->has_tag('note') ? join(' ', $biofeature->get_tag_values('note')) : '';

            $ac_src = $biofeature->primary_tag;
            defined($ignore_features->{$ac_src}) and next;

            if(($ac_src eq 'MUTAGEN') or ($ac_src eq 'VARIANT')) {
                $type = '';
                ($wt, $mt) = ($description =~ /\A(\S+)->(\S+?):/) ? ($1, $2) : ('', '');

                if($description =~ /\(in dbSNP/) {
                    $type = 'dbSNP only'; # FIXME - parse out and use the dbSNP identifier
                }
                elsif($description =~ /\(in [a-z]+/) {
                    $type = 'sample';
                }
                elsif($description =~ /\(in [A-Z]+/) {
                    $type = 'disease'; # FIXME - parse out and use the disease info
                }
                else {
                    $type = 'other';
                }

                # FIXME - a variant could have more than one type?...
            }
            elsif($ac_src eq 'MOD_RES') {
                $type = ($description =~ /\A(.*?)[\.;]/) ? $1 : '';
                $wt = '';
                $mt = '';

                # FIXME - save the enzyme information
                $enzyme_str = ($description =~ /by (.*?)[\.;]/) ? $1 : '';
                $enzyme_str =~ s/\s*and/,/;
                $enzyme_str =~ s/\//,/g;
                @enzymes = split /\s*,\s*/, $enzyme_str;
            }
            else {
                $type = '';
                $wt = '';
                $mt = '';
            }

            ($feature) = $features->get_by_source('uniprot', $ac_src, $type);
            if(!defined($feature)) {
                $unrecognised_features->{$ac_src}->{$type}++;
                next;
            }

            $score = defined($biofeature->score) ? $biofeature->score : 0;
            $start = defined($biofeature->start) ? $biofeature->start : 0;
            $end = defined($biofeature->end) ? $biofeature->end : $start;
            $feature_inst = Fist::NonDB::FeatureInst->new(
                                                          seq         => $seq,
                                                          feature     => $feature,
                                                          start_seq   => $start,
                                                          end_seq     => $end,
                                                          wt          => $wt,
                                                          mt          => $mt,
                                                          score       => $score,
                                                          description => $description,
                                                         );
            $feature_inst->add_to_pmids(@{$pmids});
            $seq->add_to_feature_insts($feature_inst);

            #print join("\t", $ac_src, $description), "\n";
        }
    }

    foreach $ac_src (keys %{$unrecognised_features}) {
        foreach $type (keys %{$unrecognised_features->{$ac_src}}) {
            if($type eq '') {
                Carp::cluck("unrecognised Feature source='uniprot' ac_src='$ac_src' for seq '", $seq->primary_id, "'");
            }
            else {
                Carp::cluck("unrecognised Feature source='uniprot' ac_src='$ac_src' type='$type' for seq '", $seq->primary_id, "'");
            }
        }
    }

    return $seq;
}

=head2 parse_fasta

 usage   : while($seq = $self->parse_fasta('sequenceDbX')){print $seq->id, "\n";}
 function: parse next sequence and it's taxon and all accessions and identifiers
           from swissprot-format uniprot files. Assign a new unique identifier.
 args    :
 returns : a Fist::NonDB::Seq object

=cut

sub parse_fasta {
    my($self, $source, $id_taxon, $ac_to_taxa) = @_;

    my $in;
    my $bioseq;
    my $id_bioseq;
    my $desc_bioseq;
    my $seq;
    my $type_alias;
    my $alias;
    my $taxon;
    my $ac_uniprot;
    my $id_uniprot;
    my $ac_primary_isoform;

    if(!defined($in = $self->in)) {
        $in = Bio::SeqIO->new(-fh => $self->fh, -format => 'fasta');
        $self->in($in);
    }

    if($bioseq = $in->next_seq) {
        $seq = Fist::NonDB::Seq->new(
                                     seq           => $bioseq->seq,
                                     len           => $bioseq->length,
                                     chemical_type => 'peptide',
                                     source        => $source,
                                     description   => $bioseq->description,
                                    );

        $id_bioseq = $bioseq->id;
        $desc_bioseq = $bioseq->description;
        if($id_bioseq =~ /^gi\|/) {
            # get aliases from NCBI-format FastA identifiers
            while($id_bioseq =~ /(\S+?)\|(\S+?)\|/g){
                $type_alias = $1;
                $alias = $2;

                if($type_alias eq 'gi') {
                    $type_alias = 'GI';
                }
                elsif($type_alias eq 'ref') {
                    $type_alias = 'RefSeq';
                }
                else {
                    warn "Warning: do no understand alias type '$type_alias'.";
                    next;
                }

                $alias = Fist::NonDB::Alias->new(seq => $seq, alias => $alias, type => $type_alias);
                $seq->add_to_aliases($alias);
            }

        }
        elsif($id_bioseq =~ /^sp\|(\S+?)\|([^\s\|]+)/) {
            # get aliases from UniProt-format FastA identifiers
            ($ac_uniprot, $id_uniprot) = ($1, $2);
            $seq->primary_id($ac_uniprot);

            if($ac_uniprot =~ /\A(\S+)-(\d+)\Z/) {
                $ac_primary_isoform = $1;
                if(defined($ac_to_taxa->{$ac_primary_isoform})) {
                    foreach $id_taxon (sort {$a <=> $b} keys %{$ac_to_taxa->{$ac_primary_isoform}}) {
                        $taxon = Fist::NonDB::Taxon->new(id => $id_taxon);
                        $seq->add_to_taxa($taxon);
                    }
                }
            }

            $alias = Fist::NonDB::Alias->new(seq => $seq, alias => $ac_uniprot, type => 'UniProtKB accession');
            $seq->add_to_aliases($alias);

            $alias = Fist::NonDB::Alias->new(seq => $seq, alias => $id_uniprot, type => 'UniProtKB ID');
            $seq->add_to_aliases($alias);

            # get aliases and gene names from Uniprot varsplic format FastA descriptions
            if($desc_bioseq =~ /(Isoform.*) of .*GN=(\S+)/) {
                $seq->name("$2 $1");
                $alias = Fist::NonDB::Alias->new(seq => $seq, alias => $2, type => 'Gene_Name');
                $seq->add_to_aliases($alias);
            }
        }
        else {
            $type_alias = $source;
            $alias = $id_bioseq;

            $alias = Fist::NonDB::Alias->new(seq => $seq, alias => $alias, type => $type_alias);
            $seq->add_to_aliases($alias);
        }

        if(defined($id_taxon)) {
            $taxon = Fist::NonDB::Taxon->new(id => $id_taxon);
            $seq->add_to_taxa($taxon);
        }
    }

    return $seq;
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

    my $type = 'Seq';
    my $fh;
    my $id_old;
    my $primary_id;
    my $name;
    my $seq;
    my $len;
    my $chemical_type;
    my $source;
    my $description;
    my $id_new;
    my $mapping_func;
    my $space;
    my $ref;
    my $hash;

    $fh = $self->fh;

    $mapping_func = sub {
        my($hash, $mapping, $type, $fh_out, $primary_id, $name, $seq, $len, $chemical_type, $source, $description) = @_;

        my $id_new;

        if(!defined($id_new = $hash->{$source}->{$chemical_type}->{$seq})) {
            $id_new = ++$mapping->{Unique}->{$type};
            $hash->{$source}->{$chemical_type}->{$seq} = $id_new;
            print $fh_out join("\t", $id_new, $primary_id, $name, $seq, $len, $chemical_type, $source, $description), "\n";

            # NOTE: only the description from the first instance of [source, chemical_type, seq] is used
        }

        return $id_new;
    };

    $space = $id_to_space->{id};
    $ref = ref $space;
    if($ref eq 'HASH') {
        if(!defined($hash = $space->{hashes}->{$type})) {
            $hash = {};
            $space->{hashes}->{$type} = $hash;
        }
    }
    else {
        $hash = undef;
    }

    while(<$fh>) {
        chomp;
        ($id_old, $primary_id, $name, $seq, $len, $chemical_type, $source, $description) = split /\t/;
        defined($description) or ($description = '');
        $id_new = $id_mapping->id_new($space, $type, $id_old, $mapping_func, $hash, $fh_out, $primary_id, $name, $seq, $len, $chemical_type, $source, $description);
        if($ref ne 'HASH') { # otherwise printing is done by $mapping_func
            # FIXME - always use a mapping function, with a default that doesn't group non-redundantly

            print $fh_out join("\t", $id_new, $primary_id, $name, $seq, $len, $chemical_type, $source, $description), "\n";
        }
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
    return 'Seq';
}

=head2 column_names

 usage   :
 function: used internally to provide the column names in order used by tsv files
 args    : none
 returns : a list of column names

=cut

sub column_names {
    return(qw/id primary_id name seq len chemical_type source description/);
}

__PACKAGE__->meta->make_immutable;
1;
