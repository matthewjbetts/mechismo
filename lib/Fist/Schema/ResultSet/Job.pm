package Fist::Schema::ResultSet::Job;

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use namespace::autoclean;

extends 'DBIx::Class::ResultSet';

=head1 NAME

 Fist::Schema::ResultSet::Job;

=cut

=head1 ACCESSORS

=cut

=head1 METHODS

=cut

=head2 next_queued

 usage   : $job = $self->next_queued($type)
 function: mark the next queued job of type '$type' on the queue as 'running' and return it
 args    : a string specifying the job type
 returns : a Job object

=cut

sub next_queued {
    my($self, $queue_name, @types) = @_;

    my $schema;
    my $query;
    my $job;

    # lock the table so that other processes can't select the same job
    $schema = $self->result_source->schema;
    $schema->storage->dbh_do(sub {my($storage, $dbh) = @_; $dbh->do("LOCK TABLES Job WRITE, Job AS me WRITE"); });  # 'AS me' because this is the table alias is sometimes used by DBIx

    $query = {status => 'queued', queue_name => $queue_name};
    (@types > 0) and ($query->{type} = \@types);
    $job = $self->search($query, {order_by => { -asc => 'id' }})->first();
    defined($job) and $job->update({status => 'running', started => time, pid => $$});

    $schema->storage->dbh_do(sub {my($storage, $dbh) = @_; $dbh->do("UNLOCK TABLES"); });

    return $job;
}

=head2 stats

 usage   : $self->stats
 function: get general stats
 args    :
 returns :

=cut

sub stats {
    my($self) = @_;

    my $stats;
    my $jobs;
    my $job;
    my $type;
    my $run_time;

    $jobs = [$self->all];
    $stats = {
              jobs             => $jobs,
              n_jobs           => {all => scalar @{$jobs}},
              queue_time       => 0,
              run_time         => 0,
              total_time       => 0,
              run_time_vs_size => [],
             };

    foreach $job (@{$jobs}) {
        $stats->{n_jobs}->{$job->type}++;
        $stats->{n_jobs}->{$job->status}++;

        if($job->status eq 'finished') {
            $run_time = $job->run_time;
            push @{$stats->{run_time_vs_size}}, {
                                                 run_time    => $run_time,
                                                 n_labels    => $job->n_labels,
                                                 n_aliases   => $job->n_aliases,
                                                 id_search   => $job->id_search,
                                                 search_name => $job->search_name,
                                                };

            $stats->{queue_time} += $job->queue_time;
            $stats->{run_time} += $run_time;
            $stats->{total_time} += $job->total_time;
        }
        elsif($job->status eq 'running') {
            $stats->{queue_time} += $job->queue_time;
        }
    }

    foreach $type ('all', 'queued', 'running', 'finished', 'error', 'short', 'long') {
        defined($stats->{n_jobs}->{$type}) or ($stats->{n_jobs}->{$type} = 0);
    }

    return $stats;
}

__PACKAGE__->meta->make_immutable;
1;

