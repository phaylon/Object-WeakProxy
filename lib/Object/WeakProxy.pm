use strict;
use warnings;

# ABSTRACT: Weakly proxying objects to avoid leakage

package Object::WeakProxy;

use Carp::Clan   6.04 qw( ^Object::WeakProxy );
use Scalar::Util qw( weaken blessed );

use aliased 'Object::WeakProxy::Instance';

use namespace::clean 0.13;

use Sub::Exporter 0.982 -setup => {
    exports => [qw( weak_proxy )],
};

sub weak_proxy {
    my $object = shift;

    my $class = blessed($object)
        or confess 'Value passed to weak_proxy must be a blessed reference';

    return $object
        if $class eq Instance;

    my $proxy = bless { 
        object  => $object,
        class   => $class,
    }, Instance;

    weaken $proxy->{object};

    return $proxy;
}

1;

__END__

=head1 SYNOPSIS

    use Object::WeakProxy qw( weak_proxy );

    {   package SomeObject;
        sub new  { bless { }, shift }
        sub data { (shift)->{data} ||= {} }
    }

    my $object = SomeObject->new;

    # wrapping an object
    my $proxy = weak_proxy($object);

    # no problem with cyclic references
    $proxy->data->{cycle} = $proxy;

=head1 DESCRIPTION

This module allows you to create proxy objects that wrap around your actual
objects. The proxy object will keep a weakened link to the original and
delegate all method calls to it, including C<can> and C<isa>. Once all other
references to the original have ceased, the proxy will throw an error when you
try to use it.

=head2 What's this for?

The original idea for this came up for the L<Catalyst> context object. If you
have the context object in C<$ctx>, you might want to stash something that
takes a reference to the context object itself. Common candidates are URI
generation callbacks.

Since the stash is managed by the context object you wish to reference, you'd
have to weaken those references if you don't want your application to leak.

One often used work-around for this tedious procedure is having a method that
takes a callback and passes in a weakly referenced context object on every
call. With L<Catalyst>s own L<Catalyst::Component::ContextClosure> this would
look something like this:

    sub foo: Chained('/') {
        my ($self, $ctx) = @_;

        $ctx->stash(uri_for_bar => $self->make_context_closure(sub {
            my ($ctx, $id) = @_;
            $ctx->uri_for_action('/bar', $id);
        }, $ctx));
    }

If you have to write lots of callbacks, they can become pretty dominant in your
actions. With a weakened proxy, the same would look like this:

    sub foo: Chained('/') {
        my ($self, $ctx) = @_;

        $ctx = weak_proxy $ctx;

        $ctx->stash(uri_for_bar => sub { 
            my ($id) = @_;
            $ctx->uri_for_action('/bar', $id);
        });
    }

Those are both explicitely verbose to keep the comparison fair. The above could
also be written as:

    $ctx->stash(uri_for_bar => sub { $ctx->uri_for_action('/bar', shift) });

As always, it's up to you how verbose you would like to be.

Also, this module is actually meant to be integrated into L<Catalyst>, so it
can be automatically applied to all user-facing context objects. This means
you don't have to concern yourself with leaking context objects in your actions
at all, since the proxy will always break a cyclic reference.

=head2 Stringification

Every proxy will stringify to C<Object::WeakProxy::Instance#$class>, with
C<$class> being replaced by the class of the proxied object.

=func weak_proxy

    my $proxy = weak_proxy($object);

Creates a new proxy object. It will throw an error if C<$object> is not a
blessed reference.

=cut
