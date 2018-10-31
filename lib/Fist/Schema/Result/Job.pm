use utf8;
package Fist::Schema::Result::Job;

=head1 NAME

Fist::Schema::Result::Job

=cut

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';
use Net::IPAddress;

=head1 TABLE: C<Job>

=cut

__PACKAGE__->table("Job");

=head1 ACCESSORS

=cut

__PACKAGE__->add_columns(
                         "id",
                         {
                          data_type => "integer",
                          extra => { unsigned => 1 },
                          is_auto_increment => 1,
                          is_nullable => 0,
                         },

                         "id_search",
                         {
                          data_type => 'varchar(20)',
                          is_nullable => 0,
                         },

                         "search_name",
                         {
                          data_type => 'varchar(255)',
                          is_nullable => 0,
                         },

                         "ipint",
                         {
                          data_type => 'bigint',
                          is_nullable => 0,
                         },

                         "hostname",
                         {
                          data_type => 'varchar(255)',
                          is_nullable => 0,
                         },

                         "queue_name",
                         {
                          data_type => 'varchar(20)',
                          is_nullable => 0,
                         },

                         "n_aliases",
                         {
                          data_type => "integer",
                          extra => { unsigned => 1 },
                          is_nullable => 0,
                         },

                         "n_labels",
                         {
                          data_type => "integer",
                          extra => { unsigned => 1 },
                          is_nullable => 0,
                         },

                         "type",
                         {
                          data_type => 'enum',
                          extra =>  {list => ["short", "long"]},
                          is_nullable => 0,
                         },

                         "status",
                         {
                          data_type => 'enum',
                          extra => {list => ["queued", "running", "finished", "error"]},
                          is_nullable => 0,
                         },

                         "queued",
                         {
                          data_type => "integer",
                          extra => { unsigned => 1 },
                          is_nullable => 0,
                         },

                         "started",
                         {
                          data_type => "integer",
                          extra => { unsigned => 1 },
                          is_nullable => 0,
                         },

                         "finished",
                         {
                          data_type => "integer",
                          extra => { unsigned => 1 },
                          is_nullable => 0,
                         },

                         "message",
                         {
                          data_type => "text",
                         },

                         "pid",
                         {
                          data_type => "integer",
                          extra => { unsigned => 1 },
                          is_nullable => 0,
                         },

                        );

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=cut

=head1 METHODS

=cut

# FIXME - storing IP addresses as BIGINT so that they can be compared more easily
# but can't het inflate and deflate to work properly (even with InflateColumn::IP)
#
#__PACKAGE__->inflate_column(
#                            'ip',
#                            {
#                             inflate => sub {
#                                 my($ipBigInt) = @_;
#                                 my $ip = Net::IP->new($ipBigInt);
#
#                                 warn "inflate: ipBigInt = '", $ipBigInt, "', ipStr = '", defined($ip) ? $ip->ip : '', "'";
#
#                                 return(defined($ip) ? $ip->ip : '0.0.0.0');
#                             },
#
#                             deflate => sub {
#                                 my($ipStr) = @_;
#                                 my $ip = Net::IP->new($ipStr);
#
#                                 warn "deflate: ipStr = '", $ipStr, "', '", defined($ip) ? $ip->intip : '', "'";
#
#                                 return(defined($ip) ? $ip->intip : 0);
#                             },
#                            }
#                           );

sub queue_time {
    my($self) = @_;

    my $time;

    $time = ($self->status ne 'queued') ? ($self->started - $self->queued) : (time - $self->queued);

    return $time;
}

sub run_time {
    my($self) = @_;

    my $time;

    if($self->status eq 'finished') {
        $time = $self->finished - $self->started;
    }
    elsif($self->status eq 'running') {
        $time = time - $self->started;
    }
    else {
        $time = 0;
    }

    return $time;
}

sub total_time {
    my($self) = @_;

    my $time;

    $time = ($self->status eq 'finished') ? ($self->finished - $self->queued) : (time - $self->queued);

    return $time;
}

sub ipstr {
    my($self) = @_;

    my $ipstr;

    $ipstr = num2ip($self->ipint);

    return $ipstr;
}

=head2 TO_JSON

 usage   :
 function:
 args    :
 returns :

=cut

sub TO_JSON {
    my($self) = @_;

    my $json;

    $json = {
             id          => $self->id,
             id_search   => $self->id_search,
             search_name => $self->search_name,
             ipint       => $self->ipint,
             ipstr       => $self->ipstr,
             queue_name  => $self->queue_name,
             n_aliases   => $self->n_aliases,
             n_labels    => $self->n_labels,
             type        => $self->type,
             status      => $self->status,
             queued      => $self->queued,
             started     => $self->started,
             finished    => $self->finished,
             message     => $self->message,
             pid         => $self->pid,
             run_time    => $self->run_time,
             queue_time  => $self->queue_time,
             total_time  => $self->total_time,
            };

    return $json;
}

__PACKAGE__->meta->make_immutable;
1;
