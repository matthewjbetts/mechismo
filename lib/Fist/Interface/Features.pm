package Fist::Interface::Features;

use Moose::Role;

=head1 NAME

 Fist::Interface::Features

=cut

=head1 ACCESSORS

=cut

=head2 features

 usage   : @features = $self->features();
 function: get all features of this object
 args    : none
 returns : a list of Fist::Interface::Feature objects

=cut

requires 'features';

=head1 ROLES

=cut

=head1 METHODS

=cut

=head2 n_features

 usage   :
 function:
 args    :
 returns :

=cut

requires 'n_features';

=head2 get

 usage   :
 function:
 args    :
 returns :

=cut

requires 'get_by_source';

1;
