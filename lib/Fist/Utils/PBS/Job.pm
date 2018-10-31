package Fist::Utils::PBS::Job;

use Moose;
use Carp ();
use Net::OpenSSH ();
use namespace::autoclean;

=head1 NAME

 Fist::Utils::PBS::Job

=cut

=head1 ACCESSORS

=cut

=head2 cput

 usage   :
 function: cpu time limit
 args    :
 returns :

=cut

has 'cput' => (is  => 'ro', isa => 'Str | Undef');

=head2 nodes

 usage   :
 function: number of nodes required
 args    :
 returns :

=cut

has 'nodes' => (is  => 'ro', isa => 'Int', default => 1);

=head2 ppn

 usage   :
 function: number of processors per node
 args    :
 returns :

=cut

has 'ppn' => (is  => 'ro', isa => 'Int', default => 1);

=head2 script

 usage   :
 function:
 args    :
 returns :

=cut

has 'script' => (is  => 'rw', isa => 'Str');

=head1 ROLES

 with 'Fist::Interface::Processes::Job';

=cut

with 'Fist::Interface::Processes::Job';

=head1 METHODS

=cut

sub BUILD {
    my($self) = @_;

    my $fh_log;

    # accessors not called on object creation, so any special stuff needs to be done here too
    $self->name();
    $self->id();
    $self->state();
    $self->write_script();

    $fh_log = $self->processes->log;
    print $fh_log $self->script, "\n//\n";
}

=head2 write_script

=cut

sub write_script {
    my($self) = @_;

    $self->script(
                  join(
                       '',
                       '#PBS -N ', $self->name, "\n",
                       '#PBS -o ', $self->stdout, "\n",
                       '#PBS -e ', $self->stderr, "\n",
                       ($self->cput ? sprintf("#PBS -l cput=%s\n", $self->cput) : ''),
                       sprintf("#PBS -l nodes=%d:ppn=%d\n", $self->nodes, $self->ppn),
                       $self->processes->email_address ? join('', '#PBS -M ', $self->processes->email_address, "\n", '#PBS -m ', $self->processes->email_conditions, "\n") : "#PBS -m n\n",
                       "echo 'PBS_JOBID' \$PBS_JOBID 1>&2\n",
                       "echo 'PBS_NODEFILE' `cat \$PBS_NODEFILE` 1>&2\n",
                       $self->cmd, "\n",
                      ),
                 );

    return $self->script;
}

=head2 submit

 usage   :
 function:
 args    :
 returns :

=cut

sub submit {
    my($self) = @_;

    my $id_pbsjob;
    my $stderr;

    !$self->processes->ssh->check_master() and !$self->connect() and return(undef);

    #print join("\t", 'START', 'submit', 'qsub', time), "\n";
    ($id_pbsjob, $stderr) = $self->processes->ssh->capture2({stdin_data => $self->script}, 'qsub -');
    #print join("\t", 'END', 'submit', 'qsub', time), "\n";

    if($self->processes->ssh->error) {
        Carp::cluck("Error running 'qsub -' over ssh: ", $self->processes->ssh->error);
        $id_pbsjob = undef;
        $self->state('Error');
    }
    else {
        chomp($id_pbsjob);
        $self->id($id_pbsjob);
        $self->state('Submitted');
    }

    return $id_pbsjob;
}

__PACKAGE__->meta->make_immutable;
1;
