package Fist::IO::Test;

use Moose;

with 'Fist::IO';

sub resultset_name {
    return('Test');
}

sub column_names {
    return();
}

__PACKAGE__->meta->make_immutable;
1;
