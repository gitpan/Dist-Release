package Dist::Release::Action::CPANUpload;

use Moose;

use CPAN::Uploader;

extends 'Dist::Release::Action';

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub check {
    my ($self) = @_;

    # do we have a pause id?
    unless ($self->distrel->config->{pause}{id}
        and $self->distrel->config->{pause}{password} ) {
        $self->error('pause id or password missing from config file');
    }
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub release {
    my $self = shift;

    $self->diag('verifying that the tarball is present');

    my @archives = <*.tar.gz> or return $self->error('no tarball found');

    if ( @archives > 1 ) {
        return $self->error( 'more than one tarball file found: ' . join ',',
            @archives );
    }

    my $tarball = $archives[0];

    $self->diag("found tarball: $tarball");

    $self->diag("uploading tarball '$tarball' to CPAN");

    my ( $id, $password ) =
      map { $self->distrel->config->{pause}{$_} } qw/ id password /;

    $self->diag( "using user '$id'" );

    my $uploader = CPAN::Uploader->new;

    unless ( $self->distrel->pretend ) {
        $uploader->upload_file( $tarball,
            { user => $id, password => $password } );
    }
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

1;
