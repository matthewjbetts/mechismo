package Fist::Interface::Feature;

use Moose::Role;

=head1 NAME

 Fist::Interface::Feature

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

=head2 source

 usage   :
 function:
 args    :
 returns :

=cut

requires 'source';

=head2 ac_src

 usage   :
 function:
 args    :
 returns :

=cut

requires 'ac_src';

=head2 id_src

 usage   :
 function:
 args    :
 returns :

=cut

requires 'id_src';

=head2 type

 usage   :
 function:
 args    :
 returns :

=cut

requires 'type';

=head2 regex

 usage   :
 function:
 args    :
 returns :

=cut

requires 'regex';

=head2 description

 usage   :
 function:
 args    :
 returns :

=cut

requires 'description';

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
             id          => $self->id,
             source      => $self->source,
             ac_src      => $self->ac_src,
             id_src      => $self->id_src,
             type        => $self->type,
             regex       => $self->regex,
             description => $self->description,
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

    print($fh
          join(
               "\t",
               $self->id,
               $self->source,
               $self->ac_src,
               $self->id_src,
               $self->type,
               $self->regex,
               $self->description,
              ),
          "\n",
         );
}

1;
