package Fist::Interface::Processes::Job;

use Moose::Role;
use Carp ();
use Net::OpenSSH ();

=head1 NAME

 Fist::Utils::PBS::Job

=cut

=head1 ACCESSORS

=cut

=head2 processes

 usage   :
 function:
 args    :
 returns :

=cut

has 'processes' => (is  => 'ro', isa => 'Any', required => 1); # FIXME - should be "isa => 'Fist::Interface::Processes'" but couldn't get this to work

=head2 name

 usage   : set on object creation
 function: name of the job, should be unique for the given Fist::Interface::Processes object
 args    :
 returns :

=cut

has 'name' => (is  => 'ro', isa => 'Str');

around 'name' => sub {
    my($orig, $self, $name_new) = @_;

    my $name_old;

    $name_old = $self->$orig();
    $name_new and $self->$orig($name_new);
    $self->processes->store_by_name($self, $name_old, $name_new);

    return $self->$orig;
};

=head2 id

 usage   :
 function: id of the job, set when the job is submitted
 args    :
 returns :

=cut

has 'id' => (is  => 'rw', isa => 'Str');

around 'id' => sub {
    my($orig, $self, $id_new) = @_;

    my $id_old;

    $id_old = $self->$orig();
    $id_new and $self->$orig($id_new);
    $self->processes->store_by_id($self, $id_old, $id_new);

    return $self->$orig;
};

=head2 stdout

 usage   :
 function: name of file to which job stdout should be written
 args    :
 returns :

=cut

has 'stdout' => (is  => 'ro', isa => 'Str');

=head2 stderr

 usage   :
 function: name of file to which job stderr should be written
 args    :
 returns :

=cut

has 'stderr' => (is  => 'ro', isa => 'Str');

=head2 cmd

 usage   :
 function: command to be run, including arguments
 args    :
 returns :

=cut

has 'cmd' => (is  => 'ro', isa => 'Str');

=head2 state

 usage   :
 function: state of the job
 args    :
 returns : a string, one of:
           - NotSubmitted
           - Submitted
           - Queued
           - Running
           - Finished
           - Error

=cut

has 'state' => (is => 'rw', isa => 'Str', default => 'NotSubmitted');

around 'state' => sub {
    my($orig, $self, $state_new) = @_;

    my $state_old;

    $state_old = $self->$orig();
    $state_new and $self->$orig($state_new);
    $self->processes->store_by_state($self, $state_old, $state_new);

    return $self->$orig;
};

=head1 ROLES

=cut

=head1 METHODS

=cut

sub BUILD {
    my($self) = @_;

    my $fh_log;

    # accessors not called on object creation, so any special stuff needs to be done here too
    $self->name();
    $self->id();
    $self->state();

    $fh_log = $self->processes->log;
}


=head2 submit

 usage   :
 function:
 args    :
 returns :

=cut

requires 'submit';

1;
