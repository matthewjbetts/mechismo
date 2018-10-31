package Fist::IO::SeqGroup;

use Moose;
use Carp ();
use Fist::Utils::IdMapping;
use Fist::NonDB::SeqGroup;
use XML::Parser;
use namespace::autoclean;

=head1 NAME

 Fist::IO::SeqGroup

=cut

=head1 ROLES

 with 'Fist::IO';

=cut

with 'Fist::IO';

=head1 METHODS

=cut

=head2 parse_uniref_xml

=cut

sub parse_uniref_xml {
    my($self, $level, $schema, $fh_seqgroup, $fh_seq_to_group) = @_;

    my $dbh;
    my $sth;
    my $fh;
    my $status;
    my $rep;
    my $seqgroup;
    my $table;
    my $row;
    my $id_seq;
    my $id_group;
    my $id_group2;
    my $ac;
    my $members;
    my $ac2id;

    $dbh = $schema->storage->dbh;
    $sth = $dbh->prepare("SELECT alias, id_seq FROM Alias WHERE type = 'UniProtKB accession'");
    $sth->{mysql_use_result} = 1;
    $sth->execute();
    $ac2id = {};
    while($row = $sth->fetchrow_arrayref) {
        $ac2id->{$row->[0]}->{$row->[1]}++;
    }

    $fh = $self->fh;
    $status = '';
    $members = {};
    $id_group = 0;
    while(<$fh>) {
        if(/\A<representativeMember>/) {
            $status = 'member';
            $rep = 1;
            ++$id_group;
        }
        elsif(/\A<member>/) {
            $status = "member";
            $rep = 0;
        }
        elsif(/\A<\/member>/ or /\A<\/representativeMember>/) {
            $status = '';
            $rep = 0;
        }
        elsif(($status eq 'member') and /\A\s*<property type="UniProtKB accession" value="(.*?)"/) {
            $ac = $1;
            if(defined($ac2id->{$ac})) {
                foreach $id_seq (keys %{$ac2id->{$ac}}) {
                    # saving non-redundantly rather than outputting here because
                    # more than one alias can map to the same sequence
                    $members->{$id_group}->{$id_seq}->{$rep}++;
                    #print join("\t", $id_group, $ac, $id_seq, $rep), "\n";;
                }
            }
        }
    }

    $id_group2 = 0;
    foreach $id_group (sort {$a <=> $b} keys %{$members}) {
        if(keys(%{$members->{$id_group}}) > 0) {
            ++$id_group2;

            print $fh_seqgroup join("\t", $id_group2, "uniref $level"), "\n";
            foreach $id_seq (sort {$a <=> $b} keys %{$members->{$id_group}}) {
                $rep = defined($members->{$id_group}->{$id_seq}->{1}) ? 1 : 0;
                print $fh_seq_to_group join("\t", $id_seq, $id_group2, $rep), "\n";
            }
        }
    }
}

# The following version using a proper XML parser is REALLLLLLLLLLLY slow... XML, why? Argh...

# XML handlers need package variables
my @uniref_xml_states;
my @uniref_xml_members;
my $uniref_xml_ac;
my $uniref_xml_level;
my $uniref_xml_schema;
my $uniref_xml_fh_seqgroup;
my $uniref_xml_fh_seq_to_group;

sub parse_uniref_xml_v1 {
    my($self, $level, $schema, $fh_seqgroup, $fh_seq_to_group) = @_;

    my $fh;
    my $parser;

    $fh = $self->fh;
    _uniref_xml_initialise($level, $schema, $fh_seqgroup, $fh_seq_to_group);
    $parser = XML::Parser->new(Handlers => {Start => \&_uniref_xml_handle_start, End => \&_uniref_xml_handle_end});
    $parser->parse($fh);
}

sub _uniref_xml_initialise {
    my($level, $schema, $fh_seqgroup, $fh_seq_to_group) = @_;

    @uniref_xml_states = ();
    @uniref_xml_members = ();
    $uniref_xml_ac = undef;
    $uniref_xml_level = $level;
    $uniref_xml_schema = $schema;
    $uniref_xml_fh_seqgroup = $fh_seqgroup;
    $uniref_xml_fh_seq_to_group = $fh_seq_to_group;
}

sub _uniref_xml_handle_start {
    my($expat, $element, %attrs) = @_;

    if($element eq 'entry') {
        push @uniref_xml_states, $element;
        @uniref_xml_members = ();
    }
    elsif($element eq 'representativeMember') {
        push @uniref_xml_states, $element;
    }
    elsif($element eq 'member') {
        push @uniref_xml_states, $element;
    }
    elsif(@uniref_xml_states) {
        if(($element eq 'property') and ($attrs{type} eq 'UniProtKB accession')) {
            if($uniref_xml_states[$#uniref_xml_states] eq 'representativeMember') {
                $uniref_xml_ac = $attrs{value};
                unshift @uniref_xml_members, $uniref_xml_ac;
            }
            elsif($uniref_xml_states[$#uniref_xml_states] eq 'member') {
                $uniref_xml_ac = $attrs{value};
                push @uniref_xml_members, $uniref_xml_ac;
            }
        }
    }
}

sub _uniref_xml_handle_end {
    my($expat, $element) = @_;

    my $ac_rep;
    my $ac_uniprot;
    my $seqgroup;
    my $alias;
    my $seen;
    my @ids;
    my $id;
    my $rep;

    if($element eq 'entry') {
        $seen = {};
        @ids = ();
        foreach $ac_uniprot (@uniref_xml_members) {
            foreach $alias ($uniref_xml_schema->resultset('Alias')->search({alias => $ac_uniprot, type => 'UniProtKB accession'}, {columns => [qw(id_seq)]})) {
                defined($seen->{$alias->seq->id}) or push(@ids, $alias->seq->id);
                $seen->{$alias->seq->id}++;
            }
        }

        if(@ids > 0) {
            $seqgroup = Fist::NonDB::SeqGroup->new(type => "uniref $uniref_xml_level");
            $seqgroup->output_tsv($uniref_xml_fh_seqgroup);

            $rep = 1;
            foreach $id (@ids) {
                print $uniref_xml_fh_seq_to_group join("\t", $id, $seqgroup->id, $rep), "\n";
                $rep = 0;
            }
        }

        pop @uniref_xml_states;
    }
    elsif($element eq 'representativeMember') {
        pop @uniref_xml_states;
    }
    elsif($element eq 'member') {
        pop @uniref_xml_states;
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
    my $type;
    my $ac;
    my $id_new;

    $fh = $self->fh;
    while(<$fh>) {
        chomp;
        ($id_old, $type, $ac) = split /\t/;
        $id_new = $id_mapping->id_new($id_to_space->{id}, 'SeqGroup', $id_old);
        #print join("\t", __PACKAGE__, $id_old, $id_new), "\n";
        print $fh_out join("\t", $id_new, $type, defined($ac) ? $ac : ''), "\n";
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
    return 'SeqGroup';
}

=head2 column_names

 usage   :
 function: used internally to provide the column names in order used by tsv files
 args    : none
 returns : a list of column names

=cut

sub column_names {
    return(qw/id type ac/);
}

__PACKAGE__->meta->make_immutable;
1;
