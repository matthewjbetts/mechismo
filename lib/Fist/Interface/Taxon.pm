package Fist::Interface::Taxon;

use Moose::Role;

=head1 NAME

 Fist::Interface::Taxon

=cut

=head1 ACCESSORS

=cut

=head2 id

 usage   :
 function:
 args    :
 returns :

=cut

requires 'id';

=head2 id_parent

 usage   :
 function:
 args    :
 returns :

=cut

requires 'id_parent';

=head2 scientific_name

 usage   :
 function:
 args    :
 returns :

=cut

requires 'scientific_name';

=head2 common_name

 usage   :
 function:
 args    :
 returns :

=cut

requires 'common_name';

=head1 ROLES

 with 'Fist::Utils::UniqueIdentifier';

=cut

with 'Fist::Utils::UniqueIdentifier';

=head1 METHODS

=cut

=head2 child_ids

=cut

requires 'child_ids';

=head2 short_name

=cut

sub short_name {
    my($self) = @_;

    my $sci;
    my @F;
    my $short;

    if(defined($sci = $self->scientific_name)) {
        @F = split /\s+/, $sci;
        ($short = substr($F[0], 0, 1) . substr($F[1], 0, 2)) =~ tr/[A-Z]/[a-z]/;
    }
    else {
        $short = 'unk';
    }

    return $short;
}

=head2 genus_dot_species

=cut

sub genus_dot_species {
    my($self) = @_;

    my $sci;
    my @F;
    my $genus_dot_species;

    if(defined($sci = $self->scientific_name)) {
        @F = split /\s+/, $sci;
        $genus_dot_species = join '.', substr($F[0], 0, 1), $F[1];
    }
    else {
        $genus_dot_species = 'unk';
    }

    return $genus_dot_species;
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
             id                => $self->id,
             id_parent         => $self->id_parent,
             scientific_name   => $self->scientific_name,
             common_name       => $self->common_name,
             short_name        => $self->short_name,
             genus_dot_species => $self->genus_dot_species,
            };

    return $json;
}

=head2 output_tsv

=cut

sub output_tsv {
    my($self, $fh) = @_;

    print $fh join("\t", $self->id, $self->id_parent, $self->scientific_name, $self->common_name), "\n";
}

1;
