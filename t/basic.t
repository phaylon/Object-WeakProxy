use strict;
use warnings;

use Test::Most              0.21;
use Scalar::Util::Refcount  1.0.2 qw( refcount);
use Object::WeakProxy       qw( weak_proxy );

throws_ok { weak_proxy 23 } qr/blessed reference/i, 
    'weak_proxy requires object argument';

do {
    package Foo;

    sub new  { bless { } }
    sub data { (shift)->{data} ||= {} }
};

my $p;

do {
    my $o = Foo->new;
    is refcount($o), 1, 'original refcount for object is 1';

    $p = weak_proxy $o;
    is refcount($o), 1, 'refcount after proxy creation still 1';

    $p->data->{cycle} = $p;
    is refcount($o), 1, 'refcount after cycle pattern still 1';

    # the extra sub { } is needed to get a real closure
    my $build = sub {
        my $c = shift;
        sub { $c->data->{value} };
    };
    
    $p->data->{value}   = 23;
    $p->data->{closure} = $build->($p);

    note 'final proxy refcount is ', refcount($p);
    is refcount($o), 1, 'refcount after closure binding still 1';
    is $p->data->{closure}->(), 23, 'closure works';

    is "$p", 'Object::WeakProxy::Instance#Foo', 'correct overload';
};

is refcount($p), 1, 'post destruction proxy refcount back to 1';
throws_ok { $p->data } qr/no longer defined/i, 
    'garbage collected object throws error';

done_testing;
