package Fist::Utils::System;

use Moose::Role;

=head1 NAME

 Fist::Utils::System - a Moose::Role

=cut

=head1 ACCESSORS

=cut

=head1 METHODS

=cut

=head2 mysystem

 usage   : $self->mysystem($cmd)
 function: uses local signal handler so global handler does not result in bad values in $? and $!
 args    :
 returns : system($cmd)

=cut

sub mysystem {
    my $self = shift;

    # http://www.perlmonks.org/?node_id=197500
    #
    # Use local signal handler so global handler
    # does not result in bad values in $? and $!

    local $SIG{CHLD} = '';
    return(system(@_));
}

1;
