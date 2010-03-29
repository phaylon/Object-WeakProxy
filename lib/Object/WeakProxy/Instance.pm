use strict;
use warnings;

# ABSTRACT: Instance of a proxy

package Object::WeakProxy::Instance;

use Carp::Clan 6.04 qw( ^Object::WeakProxy );

use namespace::clean 0.13;
use overload 
    '""'     => sub { join '#', ref($_[0]), $_[0]->{class} },
    fallback => 1;

my $assert_object = sub {
    my $object = shift;

    confess 'The proxied object is no longer defined; it was most likely garbage-collected'
        unless defined $object;

    return $object;
};

our $AUTOLOAD;

sub can {
    my $self = shift;
    return $self->{object}->$assert_object->can(@_);
}

sub isa {
    my $self = shift;
    return $self->{object}->$assert_object->isa(@_);
}

sub AUTOLOAD {
    my $self    = shift;
    (my $method = $AUTOLOAD) =~ s{\A.*::}{};

    return $self->{object}->$assert_object->$method(@_);
}

# make sure AUTOLOAD won't dispatch this.
sub DESTROY { }

1;

__END__

=head1 DESCRIPTION

This is the internal class used by L<Object::WeakProxy> to wrap objects in
a weakened container. You shouldn't use this class or package name directly.
Ever.

=method can

Delegates to the original objects C<can> method.

=method isa

Delegates to the original objects C<isa> method.

=method AUTOLOAD

Delegates all other methods to the original.

=method DESTROY

Empty method so L</AUTOLOAD> won't dispatch for it.

=head1 SEE ALSO

L<Object::WeakProxy>

=cut
