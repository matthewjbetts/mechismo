package Fist::View::JSON;

use strict;
use base 'Catalyst::View::JSON';
use JSON::Any;

=head1 NAME

Fist::View::JSON - Catalyst JSON View

=head1 SYNOPSIS

See L<Fist>

=head1 DESCRIPTION

Catalyst JSON View.

=head1 AUTHOR

Matthew Betts

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

sub encode_json {
    my($self, $c, $data) = @_;

    my $encoder;

    $encoder = JSON::Any->new(convert_blessed => 1);

    $encoder->encode($data);
}

1;
