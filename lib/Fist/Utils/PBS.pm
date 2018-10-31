package Fist::Utils::PBS;

use strict;
use warnings;
use Moose;
use Carp ();
use Net::OpenSSH ();
use Cwd qw(abs_path);
use File::Path qw(make_path);
use Fist::Utils::PBS::Job;
use namespace::autoclean;

=head1 NAME

 Fist::Utils::PBS

=cut

=head1 ACCESSORS

=cut

=head1 ROLES

 with 'Fist::Interface::Processes';

=cut

with 'Fist::Interface::Processes';

=head1 METHODS

=cut

=head2 connect

=cut

sub connect {
    my($self) = @_;

    my $ssh;
    my $max_attempts = 10;
    my $attempt;

    $attempt = 1;
    $ssh = Net::OpenSSH->new($self->host);
    while($ssh->error) {
        ($attempt >= $max_attempts) and last;
        sleep(1);
        ++$attempt;
        $ssh = Net::OpenSSH->new($self->host);
    }

    if($ssh->error) {
        $ssh = undef;
        Carp::cluck("Couldn't establish SSH connection after $attempt attempts: ", $ssh->error);
    }
    else {
        $self->ssh($ssh);
    }

    return $ssh;
}

=head2 update

 usage   :
 function: updates job statuses via qstat and examining job output files
 args    :
 returns : 1 for success, 0 for error

=cut

sub update {
    my($self) = @_;

    my $user;
    my $qselect_stdout;
    my $qselect_stderr;
    my $id;
    my $qstat_stdout;
    my $qstat_stderr;
    my $name;
    my $state;
    my $job;
    my $found;

    # update statuses by running qstat on the PBS host
    $user = $ENV{USER};
    !$self->ssh->check_master() and !$self->connect() and return(0);

    #print join("\t", 'START', 'update', 'qselect', time), "\n";
    ($qselect_stdout, $qselect_stderr) = $self->ssh->capture2({stdin_discard => 1}, "qselect -u $user");
    #print join("\t", 'END', 'update', 'qselect', time), "\n";

    if($self->ssh->error) {
        Carp::cluck("Error running 'qselect -u $user' over ssh: ", $self->ssh->error);
        return 0;
    }

    $found = {};
    foreach $id (split /^/, $qselect_stdout) {
        ($id =~ /^#END/) and next;
        chomp $id;
        !$self->ssh->check_master() and !self->connect() and return(0);

        #print join("\t", 'START', 'update', 'qstat', time), "\n";
        ($qstat_stdout, $qstat_stderr) = $self->ssh->capture2({stdin_discard => 1}, "qstat -f $id;");
        #print join("\t", 'END', 'update', 'qstat', time), "\n";

        if($self->ssh->error) {
            if($qstat_stderr =~ /\Aqstat: Unknown Job Id/) {
                # job finished between running qselect -u and qstat -f
                next;
            }
            Carp::cluck("Error running 'qstat -f $id' over ssh: ", $self->ssh->error, '; stderr: ', $qstat_stderr);
            return 0;
        }
        for(split /^/, $qstat_stdout) {
            if(/\A\s+Job_Name = (\S+)/) {
                $name = $1;
            }
            elsif(/\A\s+job_state = (\S+)/) {
                $state = $1;
                if($state =~ /\A[REW]\Z/) {
                    $state = 'Running';
                }
                else {
                    $state = 'Queued';
                }
                last;
            }
        }

        if(defined($job = $self->get_by_name($name))) {
            $job->state($state);
            $found->{$name}++;
        }
    }

    # any jobs not found above and with state other than 'NotSubmitted' must
    # have finished, maybe with an error, between running qsub and qstat.
    foreach $job ($self->all_jobs) {
        ($found->{$job->name} or ($job->state eq 'NotSubmitted')) and next;

        if(-s $job->stderr) {
            # FIXME - parse stderr for important errors
            $job->state('Error');
        }
        else {
            unlink $job->stderr;
            $job->state('Finished');
        }

        # remove empty stdout files
        (-s $job->stdout) or unlink($job->stdout);
    }

    return 1;
}

=head2 queue_size

 usage   :
 function: get number of jobs currently on the PBS host for the current user
 args    :
 returns : number of jobs, or undef on error

=cut

sub queue_size {
    my($self) = @_;

    my $user;
    my $qselect_stdout;
    my $qselect_stderr;
    my $n;

    # update statuses by running qstat on the PBS host
    $user = $ENV{USER};
    !$self->ssh->check_master() and !$self->connect() and return(0);

    #print join("\t", 'START', 'queue_size', 'qselect', time), "\n";
    ($qselect_stdout, $qselect_stderr) = $self->ssh->capture2({stdin_discard => 1}, "qselect -u $user"); # without echo, hangs if there are no jobs
    #print join("\t", 'END', 'queue_size', 'qselect', time), "\n";

    if($self->ssh->error) {
        Carp::cluck("Error running 'qselect -u $user' over ssh: ", $self->ssh->error);
        return undef;
    }

    $n = scalar(grep(!/^#/, split(/^/, $qselect_stdout)));

    return $n;
}

=head2 _create_job

 usage   :
 function:
 args    :
 returns :

=cut

sub _create_job {
    my($self, $prog, $options, $n_digits, $switch, $out_switch, $input_type, $dn_out, $name, $id, $cput, $nodes, $ppn, @input) = @_;

    my $dn_out_job;
    my $out_options;
    my $cmd;
    my $job;
    my $fn_nytprof;
    my $dn_nytprof;

    $dn_out_job = sprintf("%s%s/%0${n_digits}d", $dn_out, $name, $id);
    (-e $dn_out_job) or make_path($dn_out_job);

    $out_options = defined($out_switch) ? sprintf("%s %s", $out_switch, $dn_out_job) : '';

    if(!defined($switch)) {
        # assume switch is given with each input
        $cmd = join(' ', $prog, $options, $out_options, @input);
    }
    elsif($switch eq '<') {
        if($input_type eq 'file') {
            $cmd = sprintf("cat %s | %s %s %s", join(' ', @input), $prog, $options, $out_options);
        }
        else {
            $cmd = sprintf("echo %s | %s %s %s", join(' ', @input), $prog, $options, $out_options);
        }
    }
    else {
        $cmd = "$prog $options $out_options $switch " . join(" $switch ", @input);
    }

    if($self->nytprof and ($cmd =~ s/^perl //)) {
        $fn_nytprof = "$dn_out_job/nytprof.out";
        $dn_nytprof = "$dn_out_job/nytprofhtml";
        $cmd = "NYTPROF=file=$fn_nytprof perl -d:NYTProf $cmd\nnytprofhtml --file $fn_nytprof --out $dn_nytprof\n";
    }

    $job = Fist::Utils::PBS::Job->new(
                                      processes => $self,
                                      name      => sprintf("%s/%0${n_digits}d", $name, $id),
                                      stdout    => sprintf("%s/stdout", $dn_out_job),
                                      stderr    => sprintf("%s/stderr", $dn_out_job),
                                      cput      => $cput,
                                      nodes     => $nodes,
                                      ppn       => $ppn,
                                      cmd       => $cmd,
                                     );
}

__PACKAGE__->meta->make_immutable;
1;
