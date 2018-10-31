package Fist::Model::FistDB;

use strict;
use base 'Catalyst::Model::DBIC::Schema';

my $dsn = $ENV{FIST_DSN} ||= 'dbi:mysql:host=pevolution.bioquant.uni-heidelberg.de;dbname=fistdb';

__PACKAGE__->config(
    schema_class => 'Fist::Schema',

    connect_info => {
        dsn => $dsn,
        user => 'anonymous',
        password => '',
    }
);

=head1 NAME

Fist::Model::FistDB - Catalyst DBIC Schema Model

=head1 SYNOPSIS

See L<Fist>

=head1 DESCRIPTION

L<Catalyst::Model::DBIC::Schema> Model using schema L<Fist::Schema>

=head1 GENERATED BY

Catalyst::Helper::Model::DBIC::Schema - 0.54

=head1 AUTHOR

Matthew Betts

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
