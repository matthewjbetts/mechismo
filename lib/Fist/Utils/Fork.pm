package Fist::Utils::Fork;

use strict;
use warnings;
use Moose;
use Carp ();
use Net::OpenSSH ();
use Cwd qw(abs_path);
use File::Path qw(make_path);
use Fist::Utils::Fork::Job;
use namespace::autoclean;

$SIG{CHLD} = 'IGNORE'; # to avoid zombies in the system process table

=head1 NAME

 Fist::Utils::Fork

=cut

=head1 ACCESSORS

=cut

=head1 ROLES

 with 'Fist::Interface::Processes';

=cut

with 'Fist::Interface::Processes';

=head1 METHODS

=cut

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

    $job = Fist::Utils::Fork::Job->new(
                                       processes => $self,
                                       name      => sprintf("%s/%0${n_digits}d", $name, $id),
                                       stdout    => sprintf("%s/stdout", $dn_out_job),
                                       stderr    => sprintf("%s/stderr", $dn_out_job),
                                       cmd       => $cmd,
                                      );
}

=head2 queue_size

 usage   :
 function:
 args    :
 returns :

=cut

sub queue_size {
    my($self) = @_;

    return 0;
}

=head2 update

 usage   :
 function:
 args    :
 returns :

=cut

sub update {
    my($self) = @_;

    my $job;

    # update statuses by checking process ids
    foreach $job ($self->all_jobs) {
        if(!defined($job->id)) {
            $job->state('NotSubmitted');
        }
        elsif(kill(0, $job->id)) {
            $job->state('Running');
        }
        else {
            if(-s $job->stderr) {
                # FIXME - parse stderr for important errors
                $job->state('Error');
            }
            else {
                unlink $job->stderr;
                $job->state('Finished');
            }

            # remove empty stdout file
            (-s $job->stdout) or unlink($job->stdout);
        }
    }

    return 1;
}

__PACKAGE__->meta->make_immutable;
1;
