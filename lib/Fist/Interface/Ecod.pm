package Fist::Interface::Ecod;

use Moose::Role;

=head1 NAME

 Fist::Interface::Ecod

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

=head2 x

 usage   :
 function:
 args    :
 returns :

=cut

requires 'x';

=head2 h

 usage   :
 function:
 args    :
 returns :

=cut

requires 'h';

=head2 t

 usage   :
 function:
 args    :
 returns :

=cut

requires 't';

=head2 f

 usage   :
 function:
 args    :
 returns :

=cut

requires 'f';

=head2 name

 usage   :
 function:
 args    :
 returns :

=cut

requires 'name';

=head1 ROLES

 with 'Fist::Utils::UniqueIdentifier';

=cut

with 'Fist::Utils::UniqueIdentifier';

=head1 METHODS

=cut

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
             id   => $self->id,
             x    => $self->x,
             h    => $self->h,
             t    => $self->t,
             f    => $self->f,
             name => $self->name,
            };

    return $json;
}

=head2 output_tsv

 usage   :
 function:
 args    :
 returns :

=cut

sub output_tsv {
    my($self, $fh) = @_;

    print(
          $fh
          join(
               "\t",
               $self->id,
               $self->x ? $self->x : '',
               $self->h ? $self->h : '',
               $self->t ? $self->t : '',
               $self->f ? $self->f : '',
               $self->name,
              ),
          "\n",
         );
}

1;
