package Fist::IO;

use Moose::Role;
use PerlIO::gzip;

=head1 NAME

 Fist::IO - a Moose::Role

=cut

=head2 dn

 usage   :
 function: get/set directory name
 args    :
 returns :

=cut

has 'dn' => (is  => 'ro', isa => 'Str | Undef');

=head2 dh

 usage   :
 function: get/set directory handle. normally only set internally
 args    :
 returns :

=cut

has 'dh' => (is  => 'rw', isa => 'FileHandle | Undef');

=head2 fn

 usage   :
 function: get/set file name
 args    :
 returns :

=cut

has 'fn' => (is  => 'ro', isa => 'Str | Undef');

=head2 fh

 usage   :
 function: get/set file handle. Normally only set internally, when object is created.
 args    :
 returns :

=cut

has 'fh' => (is  => 'rw', isa => 'FileHandle | Undef');

=head1 METHODS

=cut

=head2 BUILD

 calls _open on the named file when the object is constructed

=cut

sub BUILD {
    my $self = shift;

    $self->_open;
}

=head2 _open

 usage   :
 function:  Opens the file named by $self->fn, if defined, and stores the file handle
            in $self->fh. Will open uncompressed files and .gz, .Z, and .bz2 files.
            Called when the object is constructed - no need to call it yourself.
 args    :
 returns :

=cut

sub _open {
    my($self) = @_;

    my $fn;
    my $fh;

    if(defined($fn = $self->fn)) {
        if($fn eq '-') {
            open($fh, $fn) or confess("cannot open '$fn' file for reading");
        }
        elsif(-e $fn) {
            if($fn =~ /\.gz\Z/) {
                #open($fh, "zcat $fn |") or confess("cannot open pipe from 'zcat $fn'.";) # pipes don't necessarily return errors, rather the process id of the child
                open($fh, "<:gzip", $fn) or confess("cannot open '$fn' file for reading with PerlIO::gzip.");
            }
            elsif($fn =~ /\.Z\Z/) {
                open($fh, "zcat $fn |") or confess("cannot open pipe from 'zcat $fn'."); # FIXME - pipes don't necessarily return errors, rather the process id of the child
            }
            elsif($fn =~ /\.bz2\Z/) {
                open($fh, "bzip2 -d -c $fn |") or confess("cannot open pipe from 'bzip2 -d -c $fn'."); # FIXME - pipes don't necessarily return errors, rather the process id of the child
            }
            else {
                open($fh, $fn) or confess("cannot open '$fn' file for reading.");
            }
        }
        else {
            confess "'$fn' file does not exist.";
        }
        $self->fh($fh);
    }

    return $self->fh;
}

=head2 resultset_name

 usage   :
 function: used internally to provide the result set name
 args    : none
 returns : the name of the result set

=cut

requires 'resultset_name';

=head2 column_names

 usage   :
 function: used internally to provide the column names in order used by tsv files
 args    : none
 returns : a list of column names

=cut

requires 'column_names';

=head2 set

 usage   :
 function: extra 'set' info for LOAD DATA LOCAL INFILE, depends on '@name' type column names
 args    : none
 returns : 'set' statement

=cut

sub set {
    return '';
}

=head2 tsv_id_map

 usage   : $self->tsv_id_map($id_mapping, $id_to_space, \*STDOUT);
 function: copy file contents to given file handle.
           can be overridden by Classes to allow for id mapping
 args    : Fist::Utils::IdMapping object, string, file handle GLOB
 returns : 1 on success, 0 on failure

=cut

sub tsv_id_map {
    my($self, $id_mapping, $id_to_space, $fh_out) = @_;

    my $fh;

    $fh = $self->fh;
    while(<$fh>) {
        print $fh_out $_;
    }

    return 1;
}

=head2 import_tsv

 usage   : $self->import_tsv();
 function: import tsv file in to db
 args    : none
 returns : 1 on success, 0 on error

=cut

sub import_tsv {
    my($self, $schema) = @_;

    my $fh;
    my $query;
    my $set;
    my $dbh;
    my $sth;

    $fh = $self->fh;

    # For large files it is **MUCH** faster to use LOAD DATA INFILE than $rs->populate
    # (3 seconds vs 18 minutes for ca. 440000 lines of ResMapping.)

    $dbh = $schema->storage->dbh;
    $query = sprintf "LOAD DATA LOCAL INFILE '%s' REPLACE INTO TABLE %s (%s)", $self->fn, $self->resultset_name, join(',', $self->column_names);
    ($set = $self->set) and ($query = join(' ', $query, $set));
    $| = 1;
    #print "$query;\n";

    eval {
        if(!$dbh->do($query)) {
            Carp::cluck($dbh->errstr);
            return 0;
        }
    };
    if($@) {
        Carp::cluck($@);
        return 0;
    }

    return 1;
}

=head2 get_fh

 usage   :
 function:
 args    :
 returns :

=cut

sub get_fh {
    my($self, $output, $dn_out, @keys) = @_;

    my $pair;
    my $key;
    my $suffix;
    my $fn_out;

    foreach $pair (@keys) {
        ($key, $suffix) = @{$pair};
        if(!defined($output->{$key})) {
            $output->{$key}->{fn} = "${dn_out}$key$suffix";
            $fn_out = $output->{$key}->{fn};
            if(!open($output->{$key}->{fh}, ">$fn_out")) {
                Carp::cluck("cannot open '$fn_out' file for writing");
                return 0;
            }
        }
    }

    return 1;
}

=head2 DEMOLISH

=cut

sub DEMOLISH {
    my($self) = @_;

    defined($self->fh) and close($self->fh);
}

1;
