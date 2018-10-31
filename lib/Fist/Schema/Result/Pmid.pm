use utf8;
package Fist::Schema::Result::Pmid;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Fist::Schema::Result::Pmid

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

=head1 TABLE: C<Pmid>

=cut

__PACKAGE__->table("Pmid");

=head1 ACCESSORS

=head2 pmid

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 throughput

  data_type: 'enum'
  default_value: 'none'
  extra: {list => ["high","medium","low","single","none"]}
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "pmid",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
  "throughput",
  {
    data_type => "enum",
    default_value => "none",
    extra => { list => ["high", "medium", "low", "single", "none"] },
    is_nullable => 0,
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</pmid>

=back

=cut

__PACKAGE__->set_primary_key("pmid");

=head1 RELATIONS

=head2 pmid_to_feature_insts

Type: has_many

Related object: L<Fist::Schema::Result::PmidToFeatureInst>

=cut

__PACKAGE__->has_many(
  "pmid_to_feature_insts",
  "Fist::Schema::Result::PmidToFeatureInst",
  { "foreign.pmid" => "self.pmid" },
  { cascade_copy => 0, cascade_delete => 0 },
);

# Created by DBIx::Class::Schema::Loader v0.07033 @ 2012-12-20 13:44:35
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:GIG+W3Ku/B6STt6nWztmzQ

# You can replace this text with custom code or comments, and it will be preserved on regeneration

=head1 ROLES

 with 'Fist::Interface::Pmid';

=cut

with 'Fist::Interface::Pmid';

__PACKAGE__->meta->make_immutable;
1;
