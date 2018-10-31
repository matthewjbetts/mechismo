package Fist::Utils::IdMapping;

use Moose;
use Carp ();
use namespace::autoclean;

my $mapping = {};

=head1 NAME

 Fist::Utils::IdMapping

=cut

=head2 schema

 usage   :
 function:
 args    :
 returns :

=cut

has 'schema' => (is => 'ro', isa => 'Fist::Schema');

=head1 METHODS

=cut

=head2 BUILD

  Assigns maximum values to various types of objects (below) by querying the given schema.

  Seq
  Alignment
  SeqGroup
  Frag
  ChainSegment
  Ecod
  FragGroup
  FragInst
  Contact
  ContactGroup
  Feature
  FeatureInst
  FeatureInstContact
  ContactHit
  Hsp

=cut

sub BUILD {
    my($self) = @_;

    my $rs;
    my $type;

    foreach $type (
                   'Seq',
                   'Alignment',
                   'SeqGroup',
                   'Frag',
                   'ChainSegment',
                   'Ecod',
                   'FragGroup',
                   'FragInst',
                   'Contact',
                   'ContactGroup',
                   'Feature',
                   'FeatureInst',
                   'FeatureInstContact',
                   'ContactHit',
                   'Hsp',
                  ) {
        $rs = $self->schema->resultset($type);
        $mapping->{Unique}->{$type} = $rs->get_column('id')->max();
        #print join("\t", $type, defined($mapping->{Unique}->{$type}) ? $mapping->{Unique}->{$type} : 0), "\n";
    }
}

=head2 id_new

 usage   :
 function: returns a unique identifier for the given type of object with the given
           id in the given id space. If this has not been seen before, the unique
           id is assigned by incrementing the current maximum, which is then stored
           for later use.

           WARNING: initial maxima are assigned by quering the given schema where
           appropriate. This module assumes no other inserts happen between the mapping
           object being created and the end results being inserted in to the db.

 args    :
 returns :

=cut

sub id_new {
    my($self, $space, $type, $id_old, $mapping_func, $hash, $fh_out, @values) = @_;

    my $id_new;

    if($id_old == 0) {
        $id_new = 0;
    }
    else {
        if(defined($space)) {
            if($space eq 'DB') {
                $id_new = $id_old;
            }
            elsif(ref $space eq 'HASH') {
                if(!defined($id_new = $mapping->{$space->{name}}->{$type}->{$id_old})) {
                    $id_new = $mapping_func->($hash, $mapping, $type, $fh_out, @values);
                    $mapping->{$space->{name}}->{$type}->{$id_old} = $id_new;
                }
            }
            else {
                # hashes take too much memory
                #if(!defined($id_new = $mapping->{$space}->{$type}->{$id_old})) {
                #    $id_new = ++$mapping->{Unique}->{$type};
                #    $mapping->{$space}->{$type}->{$id_old} = $id_new;
                #}

                # arrays also take too much memory
                #if(!defined($id_new = $mapping->{$space}->{$type}->[$id_old])) {
                #    $id_new = ++$mapping->{Unique}->{$type};
                #    $mapping->{$space}->{$type}->[$id_old] = $id_new;
                #}

                # use offsets instead. This assumes old ids are encountered in ascending order
                defined($mapping->{$space}->{$type}) or ($mapping->{$space}->{$type} = ++$mapping->{Unique}->{$type} - $id_old);
                $id_new = $id_old + $mapping->{$space}->{$type};
                ($id_new <= 0) and Carp::cluck("id_new <= 0. Looks like ids were not encountered in ascending order");
                ($mapping->{Unique}->{$type} < $id_new) and ($mapping->{Unique}->{$type} = $id_new);

                #print join("\t", 'MAP', $type, $space, $id_old, $id_new), "\n";
            }
        }
        else {
            Carp::cluck('space undefined');
            $id_new = $id_old;
        }
    }

    return $id_new;
}

1;
