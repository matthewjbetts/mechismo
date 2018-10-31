package Fist::Interface::GoTerm;

use Moose::Role;

=head1 NAME

 Fist::Interface::GoTerm

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

=head2 namespace

 usage   :
 function:
 args    :
 returns :

=cut

requires 'namespace';

=head2 name

 usage   :
 function:
 args    :
 returns :

=cut

requires 'name';

=head2 def

 usage   :
 function:
 args    :
 returns :

=cut

requires 'def';

=head1 ROLES

=cut

=head1 METHODS

=cut

=head2 output_tsv

 usage   :
 function:
 args    :
 returns :

=cut

sub output_tsv {
    my($self, $fh) = @_;

    print($fh
          join(
               "\t",
               $self->id,
               $self->namespace,
               $self->name,
               $self->def,
              ),
          "\n",
         );
}

1;
