package Fist::Interface::Processes;

use Moose::Role;
use Carp ();
use Cwd qw(abs_path);
use File::Path qw(make_path);

=head1 NAME

 Fist::Utils::Processes

=cut

=head1 ACCESSORS

=cut

=head2 host

 usage   :
 function:
 args    :
 returns : name of host on which to run jobs

=cut

has 'host' => (is  => 'ro', isa => 'Str', default => 'localhost');

=head2 log

 usage   :
 function: handle of file in which to log job scripts and progress
           defaults to \*STDOUT
 args    :
 returns :

=cut

has 'log' => (is  => 'ro', isa => 'FileHandle', default => sub { return \*STDOUT });

=head2 email_address

 usage   : set at object creation
 function: address for email reports
 args    : an email address
 returns : the current email address

=cut

# FIXME - ensure that the address is valid

has 'email_address' => (is  => 'ro', isa => 'Str');

=head2 email_conditions

 usage   : set at object creation
 function: when to send emails. Defaults to 'ae'
 args    : a string of PBS email conditions eg. 'ae'
 returns : the conditions as a string

=cut

has 'email_conditions' => (is  => 'ro', isa => 'Str', default => 'ae');

=head2 q_max

 usage   : set at object creation
 function: max number of jobs to have running or queued. Defaults to 200
 args    : an integer
 returns :

=cut

has 'q_max' => (is  => 'ro', isa => 'Int', default => 200);

=head2 wait

 usage   : set at object creation
 function: seconds to sleep between submitting jobs. Defaults to zero.
 args    : an integer
 returns :

=cut

has 'wait' => (is  => 'ro', isa => 'Int', default => 0);

=head2 nytprof

 usage   : set at object creation
 function: profile with -d:NYTProf and nytprofhtml (progs beginning with 'perl ' only).
 args    : boolean
 returns :

=cut

has 'nytprof' => (is  => 'ro', isa => 'Bool', default => 0);

=head2 _jobs

 usage   :
 function:
 args    :
 returns :

=cut

has '_jobs' => (is  => 'rw', isa => 'HashRef', default => sub {return {}});

=head2 ssh

 usage   :
 function:
 args    :
 returns :

=cut

has 'ssh' => (is  => 'rw', isa => 'Net::OpenSSH');

=head1 METHODS

=cut

=head2 store_by_name

 usage   :
 function:
 args    :
 returns : 1 on success, 0 on error

=cut

sub store_by_name {
    my($self, $job, $name_old, $name_new) = @_;

    if($name_new) {
        if($name_old) {
            if($name_new ne $name_old) {
                # remove value for old name
                $self->_jobs->{all_by_name}->{$name_old} = undef;
                delete $self->_jobs->{all_by_name}->{$name_old};

                # add value for new name
                if($self->_jobs->{all_by_name}->{$name_new} and ($self->_jobs->{all_by_name}->{$name_new} != $job)) {
                    Carp::cluck("job with name '$name_new' already exists");
                    return 0;
                }
                $self->_jobs->{all_by_name}->{$name_new} = $job;
            }
        }
        else {
            # add value for new name
            $self->_jobs->{all_by_name}->{$name_new} = $job;
        }
    }
    elsif($name_old) {
        # ensure is stored by old name
        if($self->_jobs->{all_by_name}->{$name_old} and ($self->_jobs->{all_by_name}->{$name_old} != $job)) {
            Carp::cluck("job with name '$name_old' already exists");
            return 0;
        }
        $self->_jobs->{all_by_name}->{$name_old} = $job;
    }

    return 1;
}

=head2 all_jobs

 usage   :
 function:
 args    :
 returns :

=cut

sub all_jobs {
    my($self) = @_;

    return(values(%{$self->_jobs->{all_by_name}}));
}

=head2 store_by_state

 usage   :
 function:
 args    :
 returns :

=cut

sub store_by_state {
    my($self, $job, $state_old, $state_new) = @_;

    my $fh_log;

    $fh_log = $self->log;

    if($state_new) {
        if($state_old) {
            if($state_new ne $state_old) {
                # remove from $state_old list
                $self->_jobs->{$state_old}->{$job->name} = undef;
                delete $self->_jobs->{$state_old}->{$job->name};

                # add to $state_new list
                $self->_jobs->{$state_new}->{$job->name} = $job;
                print $fh_log join("\t", '#STATUS', $job->name, $state_new), "\n";
           }
        }
        else {
            # add to $state_new list
            $self->_jobs->{$state_new}->{$job->name} = $job;
            print $fh_log join("\t", '#STATUS', $job->name, $state_new), "\n";
        }
    }
    elsif($state_old) {
        # ensure job is on $state_old list
        if(!defined($self->_jobs->{$state_old}->{$job->name})) {
            $self->_jobs->{$state_old}->{$job->name} = $job;
            print $fh_log join("\t", '#STATUS', $job->name, $state_old), "\n";
        }
    }
}

=head2 get_by_state

 usage   :
 function:
 args    :
 returns :

=cut

sub get_by_state {
    my($self, @states) = @_;

    my @jobs;
    my $state;

    @jobs = ();
    foreach $state (@states) {
        $self->_jobs->{$state} and push(@jobs, values(%{$self->_jobs->{$state}}));
    }

    return @jobs;
}


=head2 get_by_name

 usage   :
 function:
 args    :
 returns :

=cut

sub get_by_name {
    my($self, $name) = @_;

    return $self->_jobs->{all_by_name}->{$name};
}

=head2 store_by_id

 usage   :
 function:
 args    :
 returns :

=cut

sub store_by_id {
    my($self, $job, $id_old, $id_new) = @_;

    if($id_new) {
        if($id_old) {
            if($id_new ne $id_old) {
                # remove value for old id
                $self->_jobs->{all_by_id}->{$id_old} = undef;
                delete $self->_jobs->{all_by_id}->{$id_old};

                # add value for new id
                if($self->_jobs->{all_by_id}->{$id_new} and ($self->_jobs->{all_by_id}->{$id_new} != $job)) {
                    Carp::cluck("job with id '$id_new' already exists");
                    return 0;
                }
                $self->_jobs->{all_by_id}->{$id_new} = $job;
            }
        }
        else {
            # add value for new id
            $self->_jobs->{all_by_id}->{$id_new} = $job;
        }
    }
    elsif($id_old) {
        # ensure is stored by old id
        if($self->_jobs->{all_by_id}->{$id_old} and ($self->_jobs->{all_by_id}->{$id_old} != $job)) {
            Carp::cluck("job with id '$id_old' already exists");
            return 0;
        }
        $self->_jobs->{all_by_id}->{$id_old} = $job;
    }
}

=head2 get_by_id

 usage   :
 function:
 args    :
 returns :

=cut

sub get_by_id {
    my($self, $id) = @_;

    return $self->_jobs->{all_by_id}->{$id};
}

=head2 update

 usage   :
 function: updates job statuses
 args    :
 returns : 1 for success, 0 for error

=cut

requires 'update';

=head2 queue_size

 usage   :
 function: get number of jobs currently queued
 args    :
 returns : number of jobs, or undef on error

=cut

requires 'queue_size';

=head2 create_jobs

 usage   : $self->create_jobs(
                              prog       => 'ls',              # Program to run. Required argument
                              input      => ['2hhb', '4hhb'],  # Input. Required argument. Types:
                                                               # - list of files, one file = one input unit
                                                               # - list of strings, one string = one input unit
                                                               # - a single file, one line = one input unit
                                                               # - other types can be accommodated by the 'split' argument
                              switch     => '-idcode',         # prog command line switch for specifying input.
                                                               # Default = '' (input is last item on command line)
                                                               # '<' means input comes from stdin.

                              split      => \&split($input, $max_n_jobs),  # reference to a subroutine that takes the input
                                                                           # and splits it in to a list of inputs.

                              options    => '-e 0.01',         # options that won't vary for each job
                              out_switch => '-prefix',         # prog command line switch for output, values will be created from dn_out and job name.
                              max_n_jobs => 200,               # Split input in to this number of jobs. Default = 30
                              id_min     => 1,                 # minimum id of any UniqueIdentifier
                              id_max     => 99999999,          # maximum id of any UniqueIdentifier
                              dn_out     => './output',        # Output directory. Default = './'. Created if doesn't exist.
                              name       => 'wibble',          # Base name for output files. Default = 'fist'.
                              cput       => '00:14:49',        # Required cpu time for each PBS job. Default: unlimited if max_n_jobs <= 30, 04:59:59 otherwise
                              nodes      => 1,
                              ppn        => 1,
                             );
 function:
 args    :
 returns : number of jobs created

=cut

sub create_jobs {
    my($self, %args) = @_;

    my $job;
    my $prog;
    my $input;
    my $input_type;
    my $options_default = '';
    my $options;
    my $max_n_jobs_default = 30;
    my $max_n_jobs;
    my $dn_out_default = './';
    my $dn_out;
    my $name_default = 'fist';
    my $name;
    my $switch_default = '';
    my $switch;
    my $out_switch_default = undef;
    my $out_switch;
    my $cput;
    my $nodes = 1;
    my $ppn = 1;
    my $d;
    my $id;
    my $i;
    my $j;
    my $n_digits;
    my $cmd;
    my $out_options;
    my $dn_out_job;
    my $split;
    my $split_input;
    my $id_min;
    my $id_max;
    my $id_incr;
    my $id_start;
    my $id_limits;

    # FIXME - create new jobs given command, arguments, input units, and number of splits,
    # need way to identify name, input, output and error files of each split, and whether output should be compressed

    # parse arguments
    if(!defined($prog = $args{prog})) {
        Carp::cluck('no program specified');
        return 0;
    }

    if(!defined($input = $args{input})) {
        Carp::cluck('no input specified');
        return 0;
    }

    $options = defined($args{options}) ? $args{options} : $options_default;
    $max_n_jobs = defined($args{max_n_jobs}) ? $args{max_n_jobs} : $max_n_jobs_default;
    $dn_out = defined($args{dn_out}) ? $args{dn_out} : $dn_out_default;
    $name = defined($args{name}) ? $args{name} : $name_default;
    $switch = defined($args{switch}) ? $args{switch} : $switch_default;
    $out_switch = defined($args{out_switch}) ? $args{out_switch} : $out_switch_default;
    $split = defined($args{split}) ? $args{split} : undef;

    $id_incr = undef;
    if(defined($id_min = $args{id_min})) {
        if(defined($id_max = $args{id_max})) {
            if($id_max >= $id_min) {
                $id_start = $id_min;
                $id_incr = sprintf "%.0f", ($id_max - $id_min) / $max_n_jobs;
            }
            else {
                Carp::cluck('id_max must be >= id_min');
                return 0;
            }
        }
        else {
            Carp::cluck('if id_min is given, id_max must be given too');
            return 0;
        }
    }

    if(defined($args{cput})) {
        $cput = $args{cput};
    }
    elsif($max_n_jobs > 30) {
        $cput = '04:59:59';
    }
    else {
        $cput = undef;
    }

    defined($args{nodes}) and ($nodes = $args{nodes});
    defined($args{ppn}) and ($ppn = $args{ppn});

    if(!(-e $dn_out)) {
        make_path($dn_out);
    }
    elsif(!(-d $dn_out)) {
        Carp::cluck("'$dn_out' already exists but is not a directory");
        return 0;
    }
    $dn_out = abs_path($dn_out) . '/';

    $n_digits = length($max_n_jobs);

    # split input
    if(defined($split)) {
        $id = 0;
        foreach $split_input ($split->($input, $max_n_jobs)) {
            ++$id;
            $id_limits = _id_limits(\$id_start, $id_incr);
            $self->_create_job($prog, "$id_limits$options", $n_digits, $switch, $out_switch, $input_type, $dn_out, $name, $id, $cput, $nodes, $ppn, @{$split_input});
        }
    }
    elsif(ref($input) eq 'ARRAY') {
        if(-e $input->[0]) {
            $input_type = 'file';
            for($i = 0; $i < @{$input}; $i++) {
                $input->[$i] = abs_path($input->[$i]);
            }
        }
        else {
            $input_type = 'string';
        }

        $d = (@{$input} <= $max_n_jobs) ? 1 : sprintf("%.0f", 1 + @{$input} / $max_n_jobs);
        for($i = 0, $id = 1; $i < @{$input}; $i += $d, ++$id) {
            $j = $i + $d - 1;
            ($j >= @{$input}) and ($j = $#{$input});
            $id_limits = _id_limits(\$id_start, $id_incr);
            $self->_create_job($prog, "$id_limits$options", $n_digits, $switch, $out_switch, $input_type, $dn_out, $name, $id, $cput, $nodes, $ppn, @{$input}[$i..$j]);
        }
    }
    elsif(ref($input) eq '') {
        Carp::cluck("can currently only split ARRAY input or by giving a subroutine with the 'split' argument");
        return 0;
    }

    return 1;
}

=head2 _id_limits

 usage   :
 function:
 args    :
 returns :

=cut

sub _id_limits {
    my($id_start, $id_incr) = @_;

    my $id_end;
    my $id_limits;

    if(defined($id_incr)) {
        $id_end = ${$id_start} + $id_incr - 1;
        $id_limits = " --id_min ${$id_start} --id_max $id_end ";
        ${$id_start} += $id_incr;
    }
    else {
        $id_limits = '';
    }

    return $id_limits;
}

=head2 _create_job

 usage   :
 function:
 args    :
 returns :

=cut

requires '_create_job';

# FIXME - read log file and restart from last viable position

=head2 submit

 usage   :
 function: submit unsubmitted jobs, up to a maximum number running (or queued, if on PBS)
 args    :
 returns : 1 on success, 0 on error

=cut

sub submit {
    my($self) = @_;

    my $job;
    my $q;
    my $id_job;
    my $max_attempts = 10;
    my $n_attempts;

    # update states of jobs
    $self->update;

    # submit unsubmitted jobs, but only have a maximum number
    # for the user on the PBS queue at any one time
    $q = $self->queue_size;
    foreach $job ($self->get_by_state('NotSubmitted')) {
        while(!defined($q) or ($q >= $self->q_max)) {
            sleep(60);
            $q = $self->queue_size;
        }

        $id_job = $job->submit;
        $n_attempts = 1;
        while(!defined($id_job) and ($n_attempts < $max_attempts)) {
            sleep(60);
            $id_job = $job->submit;
            ++$n_attempts;
        }

        if(defined($id_job)) {
            ++$q;
        }
        elsif($n_attempts >= $max_attempts) {
            Carp::cluck("Error submitting job. Giving up after $n_attempts attempts.");
        }
        else {
            Carp::cluck('Error submitting job.');
        }
    }

    return 1;
}

=head2 monitor

 usage   :
 function: monitor queue until all jobs have finished
 args    :
 returns : 1 on success, 0 on error

=cut

sub monitor {
    my($self) = @_;

    my $job;
    my @all;
    my @finished;
    my $n_all;
    my $n_finished;
    my $n_finished_p;
    my $wait;
    my $wait_max = 60;
    my $d = 1; # amount by which to increment / decrement wait time

    @all = $self->all_jobs;
    $n_all = scalar @all;
    $n_finished = 0;

    $wait = 0;
    while($n_finished < $n_all) {
        $n_finished_p = $n_finished;

        $self->update;
        @finished = $self->get_by_state('Finished', 'Error');
        $n_finished = scalar @finished;

        # adjust time to wait until re-checking the queue based on how much
        # the number of finished jobs has changed since the last check
        if($n_finished == $n_all) {
            $wait = 0;
        }
        elsif($n_finished > $n_finished_p) {
            ($wait >= $d) and ($wait -= $d);
        }
        else {
            ($wait < $wait_max) and ($wait += $d);
            ($wait > $wait_max) and ($wait = $wait_max);
        }

        sleep($wait);
    }

    return 1;
}

1;
