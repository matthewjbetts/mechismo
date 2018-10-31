package Fist::Utils::Fork::Job;

use strict;
use warnings;

use Moose;
use POSIX 'setsid';
use Carp ();
use namespace::autoclean;

=head1 NAME

 Fist::Utils::Fork::Job

=cut

=head1 ACCESSORS

=cut

=head1 ROLES

 with 'Fist::Interface::Processes::Job';
 with 'Fist::Utils::System';

=cut

with 'Fist::Interface::Processes::Job';
with 'Fist::Utils::System';

=head1 METHODS

=cut

=head2 submit

 usage   :
 function:
 args    :
 returns :

=cut

sub submit {
    my($self) = @_;

    my $pid;
    my $cmd;
    my $stat;

    select(STDOUT);
    $| = 1;
    $pid = fork();

    # undef = could not fork
    # -1    = not forked
    #  0    = this process is the child process
    # >0    = this process is the parent process, the pid is that of the child

    if(!defined($pid)) { # can't fork
        Carp::cluck('could not fork');
        $self->state('Error');
        return(0);
    }
    elsif($pid != 0) { # parent process
        # save the pid (which is of the child process) for later monitoring
        $self->id($pid);
        $self->state('Submitted');

        ($pid != -1) and return($self->id);
    }

    if($pid <= 0) {
        #  0 = child process
        # -1 = not forked, parent and child blocks done in same process

        if(!setsid) {
            Carp::cluck('could not set session ID');
            $self->_exit($pid);
        }

        $cmd = join(' ', $self->cmd, '1>', $self->stdout, '2>', $self->stderr);
        $stat = $self->mysystem($cmd);
        $stat >>= 8;
        if($stat != 0) {
            Carp::cluck("'$cmd' command failed with status $stat: $!");
            $self->_exit($pid);
        }

        # exit so that the child doesn't stray into code for the parent
        ($pid == 0) and $self->_exit($pid);
    }

    return $self->id;
}

sub _exit {
    my($self, $pid) = @_;

    if($pid == 0) {
        # close the following so that the parent isn't
        # kept alive waiting for the child to finish
        close(STDIN);
        close(STDOUT);
        close(STDERR);
    }

    exit(0);
}


__PACKAGE__->meta->make_immutable;
1;
