package Dist::Release::Action::VCS::Tag::Git;

use Moose;

extends 'Dist::Release::Step';

use version 'qv';

our $VERSION = '0.0_5';

has '+distrel' => ( handles => [qw/ vcs version /], );

sub check {
    my $self = shift;

    my $version = $self->version;

    my $last_tagged_version = $self->last_tagged_version;

    $self->diag("dist version: $version");
    $self->diag("last tagged version: $last_tagged_version");

    $self->error("version hasn't been incremented")
      unless qv($last_tagged_version) < qv($version);
}

sub release {
    my $self = shift;

    my $git = $self->vcs;

    $git->command( tag => $self->version );
}

sub last_tagged_version {
    my $self = shift;
    my $git  = $self->vcs;

    no warnings qw/ uninitialized /;

    my ( $git_v, $past );

    # TODO: make this safe from infinite looping
    while ( $git_v !~ /^v\d+/ ) {    # isn't a version
        ( $git_v, $past ) = split '-' => $git->command(
            describe => '--tags',
            ( $git_v . '^' ) x !!$git_v
        );
    }

    return wantarray ? ( $git_v, $past ) : $git_v;

}

1;

