package Fist::View::Web;

use strict;
use warnings;

use base 'Catalyst::View::TT';
use Fist::Utils::Web;

__PACKAGE__->config(
                    TEMPLATE_EXTENSION => '.tt',
                    render_die         => 1,
                    WRAPPER            => 'wrapper.tt',
                    #EVAL_PERL          => 1,
                   );

=head1 NAME

Fist::View::Web - TT View for Fist

=head1 DESCRIPTION

TT View for Fist.

=head1 SEE ALSO

L<Fist>

=head1 CUSTOM VIRTUAL METHODS

=cut

use Moose;

around template_vars => sub {
    my($orig, $self, @args) = @_;

    return(
           hours_mins_secs  => \&Fist::Utils::Web::hours_mins_secs,

           $self->$orig(@args),
          );
};

no Moose;

=head1 AUTHOR

Matthew Betts

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
