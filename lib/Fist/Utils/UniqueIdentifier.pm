package Fist::Utils::UniqueIdentifier;

use Moose::Role;
use Carp ();

my $id_min = 1; # the minimum id available
my $ids_min = {}; # the minimum id available for a particular interface
my $id_max = 4294967295; # the maximum id available (max value of sql unsigned integer)

=head1 NAME

 Fist::Utils::UniqueIdentifier - a Moose::Role

=cut

around 'id' => sub {
    my($orig, $self, $id) = @_;

    my $class;
    my $meta;
    my $interfaces;
    my $role;
    my $name;
    my $my_id_min;

    $class = ref $self;
    $meta = $class->meta;

    # id should be unique across all the interfaces
    # implemented by this object
    $interfaces = {};
    foreach my $role ($meta->calculate_all_roles) {
        $name = $role->name;
        #($name =~ /Interface/) and $interfaces->{$name}++;
        if($name =~ /Interface/) {
            $interfaces->{$name}++;
        }
    }
    $interfaces = [keys %{$interfaces}];
    $my_id_min = 0;
    foreach $name (@{$interfaces}) {
        defined($ids_min->{$name}) or ($ids_min->{$name} = $id_min);
        ($my_id_min < $ids_min->{$name}) and ($my_id_min = $ids_min->{$name})
    }

    if(defined($id)) {
        if($id < $my_id_min) {
            Carp::cluck("identifier $id may already be in use");
        }
        else {
            $self->$orig($id);
            $my_id_min = $id++;
            foreach $name (@{$interfaces}) {
                $ids_min->{$name} = $my_id_min;
            }
        }
    }
    elsif(!defined($self->$orig)) {
        if($my_id_min > $id_max) {
            Carp::cluck("above max value for identifier");
        }
        else {
            $self->$orig($my_id_min);
            ++$my_id_min;
            foreach $name (@{$interfaces}) {
                $ids_min->{$name} = $my_id_min;
            }
        }
    }

    return $self->$orig;
};

=head1 METHODS

=cut

sub set_id_limits {
    my($min, $max) = @_;

    $id_min = $min;
    $id_max = $max;
}

1;
