
#########################

use Test::More tests => 4;
BEGIN { use_ok('HTML::GenerateUtil') };
use HTML::GenerateUtil qw(:consts $H set_paranoia);
use strict;

is ('<foo {}="{}">bar</foo>', $H->foo({ "{}" => "{}"}, "bar" ) );
set_paranoia(1);
is ('<foo {}="&#123;&#125;">bar</foo>', $H->foo({ "{}" => "{}"}, "bar" ) );
set_paranoia(0);
is ('<foo {}="{}">bar</foo>', $H->foo({ "{}" => "{}"}, "bar" ) );

