package Fist::Utils::Cache;

use Moose::Role;
use CHI;

=head1 NAME

 Fist::Utils::Cache - a Moose::Role

=cut

=head2 cache

=cut

my $cache = CHI->new(
                     #driver   => 'RawMemory',
                     driver   => 'Memory',
                     global   => 1,
                     max_size => 1 * 1024 * 1024 * 1024, # max_size = 1gb
                    );

sub cache {
    return $cache;
}

=head2 cache_key

=cut

sub cache_key {
    my($self, @suffixes) = @_;

    my $key;

    $key = join ':', ref($self), $self->id, @suffixes;

    return $key;
}

# FIXME - also want to cache objects, eg of type Seq, by their id and retrieve them
#
# see ContactHit->get_hsp
#     ContactHit->get_seq
#
# every package will need
# - a way to set an object if it doesn't exist in the cache, inc. freezing the object if necessary
# - a way to get the object from the cache, inc. thawing if necessary
#
# could require them to implement
# - get($object_type, @ids)
# - set($object_type, @ids)
#
# , where @ids is the information required to uniquely define the object (eg. id_seq)

1;
