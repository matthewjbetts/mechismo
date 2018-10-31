package Fist::Interface::Seqs;

use Moose::Role;

=head1 NAME

 Fist::Interface::Seqs

=cut

=head1 ACCESSORS

=cut

=head2 seqs

 usage   : @seqs = $self->seqs();
 function: get all sequences of this object
 args    : none
 returns : a list of Fist::Interface::Seq objects

=cut

requires 'seqs';

=head2 tempdir

 usage   : used internally
 function: get/set temporary directory
 args    : File::Temp::Dir object
 returns : File::Temp::Dir object

=cut

has 'tempdir' => (is => 'rw', isa => 'File::Temp::Dir');

=head2 cleanup

 usage   : used internally
 function: whether or not to delete the temporary files
 args    : boolean
 returns : boolean

=cut

has 'cleanup' => (is => 'rw', isa => 'Bool', default => 1);

=head1 ROLES

 with 'Fist::Utils::Muscle';
 with 'Fist::Utils::Blast';
 with 'Fist::Utils::Hmmscan';
 with 'Fist::Utils::Hmmalign';

=cut

with 'Fist::Utils::Blast';
with 'Fist::Utils::Muscle';
with 'Fist::Utils::Hmmalign';

=head1 METHODS

=cut

1;