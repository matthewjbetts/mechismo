package Fist::Utils::Table;

use Moose;
use JSON::Any;
use Carp ();
use namespace::autoclean;

=head1 NAME

 Fist::Utils::Table

=cut

=head1 ACCESSORS

=cut

=head2 column_names

 usage   :
 function:
 args    :
 returns :

=cut

has 'column_names' => (is  => 'rw', isa => 'ArrayRef[Any]');

=head2 _column_name_hash

 usage   :
 function:
 args    :
 returns :

=cut

has '_column_name_hash' => (is  => 'rw', isa => 'HashRef[Any]');

=head2 add_column

 usage   :
 function:
 args    :
 returns :

=cut

sub add_column {
    my($self, @column_names) = @_;

    my $column_name;
    my @my_names;

    @my_names = ();
    foreach $column_name (@column_names) {
        if(defined($self->_column_name_hash->{$column_name})) {
            Carp::cluck("column with name '$column_name' already defined");
            next;
        }
        else {
            push @my_names, $column_name;
            $self->_column_name_hash->{$column_name}++;
        }
    }

    push @{$self->column_names}, @my_names;
}

=head2 row_ids

 usage   :
 function:
 args    :
 returns :

=cut

has 'row_ids' => (is  => 'rw', isa => 'ArrayRef[Any]', default => sub { return []; });

=head2 add_row

 usage   :
 function:
 args    :
 returns :

=cut

sub add_row {
    my($self, @row_ids) = @_;

    my @my_ids;
    my $row_id;

    @my_ids = ();
    foreach $row_id (@row_ids) {
        if(defined($self->_hash->{$row_id})) {
            Carp::cluck("row with id '$row_id' already defined");
            next;
        }
        else {
            push @my_ids, $row_id;
            $self->_hash->{$row_id} = {};
        }
    }

    push @{$self->row_ids}, @row_ids;
}

=head2 get_row

 usage   :
 function:
 args    :
 returns :

=cut

sub get_row {
    my($self, $id) = @_;

    return $self->_hash->{$id};
}

=head2 delete_row

 usage   :
 function:
 args    :
 returns :

=cut

sub delete_row {
    my($self, @row_ids) = @_;

    my $row_id;

    foreach $row_id (@row_ids) {
        $self->_hash->{$row_id} = undef;
        delete $self->_hash->{$row_id};
    }
}

=head2 _hash

 usage   :
 function:
 args    :
 returns :

=cut

has '_hash' => (is  => 'rw', isa => 'HashRef[Any]', default => sub { return {}; });

=head1 METHODS

=cut


=head2 element

 usage   : $self->element($row_id, $column_name);
 function: get/set the element identified by the given row and column names
 args    : row and column names
 returns : the element

=cut

sub element {
    my($self, $row_id, $column_name, $value) = @_;

    my $hash;

    defined($value) and ($self->_hash->{$row_id}->{$column_name} = $value);

    return $self->_hash->{$row_id}->{$column_name};
}

=head2 output_sv

 usage   : $self->output_sv($fh, $column_separator, $value_separator);
 function: output the table as a string of separated values, one row per line.
           row names are assumed to be identifiers only and are not printed.
 args    : a file handle, default = \*STDOUT
           a column separator, default = "\t"
           a value separator, default = '' (empty string)
           row_id, default = all rows
 returns : nothing

=cut

sub output_sv {
    my($self, $fh, $column_separator, $value_separator, @row_ids) = @_;

    my $tsv;
    my $column_name;
    my $row_id;
    my @row;
    my $value;
    my $ref;
    my $json_encoder;

    defined($fh) or ($fh = \*STDOUT);
    defined($column_separator) or ($column_separator = "\t");
    defined($value_separator) or ($value_separator = '');
    (@row_ids > 0) or (@row_ids = @{$self->row_ids});

    $column_separator = join '', $value_separator, $column_separator, $value_separator;

    print $fh $value_separator, join($column_separator, @{$self->column_names}), $value_separator, "\n";

    $json_encoder = JSON::Any->new(convert_blessed => 1);
    foreach $row_id (@row_ids) {
        @row = ();
        foreach $column_name (@{$self->column_names}) {
            $value = $self->element($row_id, $column_name);
            if(defined($value)) {
                $ref = ref $value;
                ($ref ne '') and ($value = $json_encoder->encode($value));
            }
            else {
                push @row, '';
            }
            push @row, defined($value) ? $value : '';
        }
        print $fh $value_separator, join($column_separator, @row), $value_separator, "\n";
    }

    return $tsv;
}

=head2 array_ref

 usage   : $self->array_ref;
 function: get the table as a reference to an array of array references,
           with column name as the first row. Undefined values are converted
           to empty strings.
 args    : none
 returns : an array reference

=cut

sub array_ref {
    my($self) = @_;

    my $ref;
    my $row_id;
    my $row;
    my $column_name;
    my $value;

    $ref = [];
    push @{$ref}, $self->column_names;

    foreach $row_id (@{$self->row_ids}) {
        $row = [];
        foreach $column_name (@{$self->column_names}) {
            $value = $self->element($row_id, $column_name);
            defined($value) or ($value = '');
            push @{$row}, $value;
        }
        push @{$ref}, $row;
    }

    return $ref;
}

=head2 TO_JSON

 usage   : $self->array_ref;
 function: get the table as a reference to an array of array references,
           with column name as the first row.
 args    : none
 returns : an array reference

=cut

sub TO_JSON {
    my($self) = @_;

    return $self->array_ref;
}

1;
