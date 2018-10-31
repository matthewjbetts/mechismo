use utf8;
package Fist::Schema::Result::Expdta;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Fist::Schema::Result::Expdta

=cut

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';

=head1 COMPONENTS LOADED

=over 4

=item * L<DBIx::Class::InflateColumn::DateTime>

=back

=cut

__PACKAGE__->load_components("InflateColumn::DateTime");

=head1 TABLE: C<Expdta>

=cut

__PACKAGE__->table("Expdta");

=head1 ACCESSORS

=head2 idcode

  data_type: 'char'
  is_foreign_key: 1
  is_nullable: 0
  size: 4

=head2 expdta

  data_type: 'enum'
  default_value: 'ELECTRON DIFFRACTION'
  extra: {list => ["ELECTRON DIFFRACTION","ELECTRON MICROSCOPY","ELECTRON CRYSTALLOGRAPHY","CRYO-ELECTRON MICROSCOPY","SOLUTION SCATTERING","FIBER DIFFRACTION","FLUORESCENCE TRANSFER","NEUTRON DIFFRACTION","POWDER DIFFRACTION","SOLUTION NMR","THEORETICAL MODEL","X-RAY DIFFRACTION"]}
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "idcode",
  { data_type => "char", is_foreign_key => 1, is_nullable => 0, size => 4 },
  "expdta",
  {
    data_type => "enum",
    default_value => "ELECTRON DIFFRACTION",
    extra => {
      list => [
        "ELECTRON DIFFRACTION",
        "ELECTRON MICROSCOPY",
        "ELECTRON CRYSTALLOGRAPHY",
        "CRYO-ELECTRON MICROSCOPY",
        "SOLUTION SCATTERING",
        "FIBER DIFFRACTION",
        "FLUORESCENCE TRANSFER",
        "NEUTRON DIFFRACTION",
        "POWDER DIFFRACTION",
        "SOLUTION NMR",
        "THEORETICAL MODEL",
        "X-RAY DIFFRACTION",
      ],
    },
    is_nullable => 0,
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</idcode>

=item * L</expdta>

=back

=cut

__PACKAGE__->set_primary_key("idcode", "expdta");

=head1 RELATIONS

=head2 idcode

Type: belongs_to

Related object: L<Fist::Schema::Result::Pdb>

=cut

__PACKAGE__->belongs_to(
  "pdb",
  "Fist::Schema::Result::Pdb",
  { idcode => "idcode" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2012-12-20 13:44:34
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:gIjgqNPj6vH63PlXbhyJKw
# You can replace this text with custom code or comments, and it will be preserved on regeneration

=head1 ROLES

 with 'Fist::Interface::Expdta';

=cut

with 'Fist::Interface::Expdta';

__PACKAGE__->meta->make_immutable;
1;
