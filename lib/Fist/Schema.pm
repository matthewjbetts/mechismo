use utf8;
package Fist::Schema;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use Moose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Schema';

__PACKAGE__->load_namespaces;


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2012-12-20 13:44:33
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:LYt3zvu43MjZGWD4PQAs0A

# You can replace this text with custom code or comments, and it will be preserved on regeneration

=head1 METHODS

=cut

=head2 disable_log_bin

 usage   : $schema->disable_log_bin();

=cut

sub disable_log_bin {
    my($self, $name) = @_;

    my $dbh;
    my $query;

    $dbh = $self->storage->dbh;
    eval {
        $query = 'SET sql_log_bin = 0;';
        #print "$query\n";
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

=head2 enable_log_bin

 usage   : $schema->enable_log_bin();

=cut

sub enable_log_bin {
    my($self, $name) = @_;

    my $dbh;
    my $query;

    $dbh = $self->storage->dbh;
    eval {
        $query = 'SET sql_log_bin = 1;';
        #print "$query\n";
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

=head2 disable_keys

 usage   : $schema->disable_keys($table_name);
           # insert some data in to the named table
           $schema->enable_keys($table_name);

 function: Runs 'ALTER TABLE $table_name DISABLE KEYS;' to allow for faster insertions
 args    :
 returns : 1 on success, 0 on error

=cut

sub disable_keys {
    my($self, $name) = @_;

    my $dbh;
    my $query;

    $dbh = $self->storage->dbh;
    eval {
        $query = "ALTER TABLE $name DISABLE KEYS";
        #print "$query\n";
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

=head2 enable_keys

 usage   : $schema->disable_keys($table_name);
           # insert some data in to the named table
           $schema->enable_keys($table_name);

 function: Runs 'ALTER TABLE $table_name ENABLE KEYS;'
 args    :
 returns : 1 on success, 0 on error

=cut

sub enable_keys {
    my($self, $name) = @_;

    my $dbh;
    my $query;

    $dbh = $self->storage->dbh;
    eval {
        $query = "ALTER TABLE $name ENABLE KEYS";
        #print "$query\n";
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

=head2 disable_foreign_keys

 usage   : $schema->disable_foreign_keys();
           # insert some data
           $schema->enable_foreign_keys();

 function: Runs 'SET foreign_key_checks=0;' to allow for faster insertions
 args    :
 returns : 1 on success, 0 on error

=cut

sub disable_foreign_keys {
    my($self) = @_;

    my $dbh;
    my $query;

    $dbh = $self->storage->dbh;
    eval {
        $query = "SET foreign_key_checks=0;";
        #print "$query\n";
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

=head2 enable_foreign_keys

 usage   : $schema->disable_foreign_keys();
           # insert some data
           $schema->enable_foreign_keys();

 function: Runs 'SET foreign_key_checks=0;' to allow for faster insertions
 args    :
 returns : 1 on success, 0 on error

=cut

sub enable_foreign_keys {
    my($self) = @_;

    my $dbh;
    my $query;

    $dbh = $self->storage->dbh;
    eval {
        $query = "SET foreign_key_checks=1;";
        #print "$query\n";
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

=head2 disable_query_cache

 usage   : $schema->disable_query_cache();

=cut

sub disable_query_cache {
    my($self) = @_;

    my $dbh;
    my $query;

    $dbh = $self->storage->dbh;
    eval {
        $query = 'SET SESSION query_cache_type = 0;';
        #print "$query\n";
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

__PACKAGE__->meta->make_immutable(inline_constructor => 0);
1;
