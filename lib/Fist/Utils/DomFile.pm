package Fist::Utils::DomFile;

use Moose::Role;
use File::Temp ();

=head1 NAME

 Fist::Utils::DomFile - a Moose::Role

=cut

=head1 ACCESSORS

=cut

=head2 doms

 usage   : $self->doms
 function: method required of classes that consume this role
 args    : none
 returns : objects with fn, id, and dom methods

=cut

requires 'doms';

=head1 METHODS

=cut

=head2 write_domfile

 usage   : writes a STAMP format domain file
 function:
 args    :
 returns : a File::Temp object

=cut

sub write_domfile {
    my($self, $tmpfile) = @_;

    my $dom;
    my $n_doms;

    defined($tmpfile) or ($tmpfile = File::Temp->new(DIR => $self->tempdir, UNLINK => $self->cleanup));
    $n_doms = 0;
    foreach $dom ($self->doms) {
        printf $tmpfile "%s %s { %s }\n", $dom->fn, $dom->id, $dom->dom;
        $n_doms++;
    }
    ($n_doms > 0) or ($tmpfile = undef);

    return $tmpfile;
}

1;
