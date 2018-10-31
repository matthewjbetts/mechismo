package Fist::NonDB::Features;

use strict;
use warnings;
use Moose;
use File::Path qw(make_path);
use Fist::Utils::Table;
use Fist::Utils::Web;
use Fist::NonDB::Network;
use Fist::Interface::Seq;

=head1 NAME

 Fist::NonDB::Features

=cut

=head1 ACCESSORS

=cut

has 'features' => (is => 'rw', isa => 'ArrayRef[Fist::Interface::Feature]', default => sub {return []}, auto_deref => 1);
has '_by_source' => (is => 'rw', isa => 'HashRef[Ant]', default => sub {return {}}, auto_deref => 1);

=head1 METHODS

=cut

=head2 n_features

=cut

sub n_features {
    my($self) = @_;

    return scalar @{$self->{features}};
}

=head2 add_new

=cut

sub add_new {
    my($self, @features) = @_;

    my $feature;

    push @{$self->features}, @features;
    foreach $feature (@features) {
        $self->_by_source->{$feature->source}->{$feature->ac_src}->{$feature->type} = $feature;
    }
}

=head2 get_by_source

=cut

sub get_by_source {
    my($self, $source, $ac_src, $type) = @_;

    my @features;

    @features = ();
    if(!defined($ac_src)) {
        foreach $ac_src (keys %{$self->_by_source->{$source}}) {
            foreach $type (keys %{$self->_by_source->{$source}->{$ac_src}}) {
                push @features, $self->_by_source->{$source}->{$ac_src}->{$type};
            }
        }
    }
    elsif(!defined($type)) {
        $type = '';
        push @features, $self->_by_source->{$source}->{$ac_src}->{$type};
    }
    else {
        push @features, $self->_by_source->{$source}->{$ac_src}->{$type};
    }

    return @features;
}

=head1 ROLES

 with 'Fist::Interface::Features';

=cut

with 'Fist::Interface::Features';

__PACKAGE__->meta->make_immutable;
1;
