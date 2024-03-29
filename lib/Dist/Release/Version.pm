package Dist::Release::Version;

use strict;
use warnings;

use Moose::Policy 'MooseX::Policy::SemiAffordanceAccessor';
use Moose;

use Perl6::Slurp;
use List::Util qw/ reduce /;
our $VERSION = '0.0_5';

use overload '""' => sub { $_[0]->version };

has file => (
    default => 'distversionrc',
    is      => 'ro',
);

has code => ( is => 'ro', );

has files => ( is => 'rw', );

sub BUILD {
    my $self = shift;

    my %files;

    if ( my $code = $self->code ) {
        %files = eval $code;
        die $@ if $@;
    }
    else {
        my $c = $self->file;
        die "config file $c not found\n" unless -f $c;

        %files = do $c;
    }

    $self->set_files( \%files );
}

sub version {
    my $self  = shift;
    my %files = %{ $self->files };
    my %version;

    for my $file ( keys %files ) {
        $version{$file} = $self->file_version($file);
    }

    no warnings qw/ uninitialized /;
    unless ( reduce { $a eq $b ? $a : undef } grep { $_ } values %version ) {
        no warnings qw/ uninitialized /;
        die "mismatched versions\n",
          map { "\t$version{$_}\t$_\n" } keys %version;
    }

    use List::Util qw/ first /;
    return first { $_ } values %version;
}

sub file_version {
    my ( $self, $file ) = @_;
    my $action = $self->files->{$file};

    my $code = slurp $file or die "can't open file $file: $!";

    my $found_version;
    my $doc;

    my $success = 1;
    my @v;

    for my $act ( ref $action eq 'ARRAY' ? @$action : $action ) {
        if ( ref $act eq 'CODE' ) {
            use List::MoreUtils qw/ uniq /;
            @v = uniq $act->($code);
        }
        else {
            while ( $code =~ /$act/g ) {
                push @v, $1;
            }
        }
    }
    @v = uniq @v;
    if ( @v > 1 ) {
        die "mismatched versions for file $file: @v";
    }
    return $v[0];
}

'end of Dist::Release::Version';
