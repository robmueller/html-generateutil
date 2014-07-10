
#########################

use Test::More tests => 35;
BEGIN { use_ok('HTML::GenerateUtil') };
use HTML::GenerateUtil qw(:consts $H $E);
use strict;

is ('<foo>', $H->foo() );
is ('<foo>', $H->foo(undef, GT_ESCAPEVAL));
is ('<foo />', $H->foo(undef, GT_CLOSETAG));
is ('<foo a="abc">', $H->foo({ a => 'abc' }));
is ('<foo abc="abc">', $H->foo({ AbC => 'abc' }));
is ('<foo abc="abc" />', $H->foo({ AbC => 'abc' }, undef, GT_CLOSETAG));
is ('<foo a="abc">bar</foo>', $H->foo({ a => 'abc' }, 'bar'));
is ('<foo a="abc">bar</foo>' . "\n", $H->foo({ a => 'abc' }, 'bar', GT_ADDNEWLINE));
is ('<foo a="abc">ba<>"&r</foo>', $H->foo({ a => 'abc' }, 'ba<>"&r'));
is ('<foo a="abc">ba&lt;&gt;&quot;&amp;r</foo>', $H->foo({ a => 'abc' }, 'ba<>"&r', GT_ESCAPEVAL));
is ('<foo a="abc" />ba&lt;&gt;&quot;&amp;r</foo>', $H->foo({ a => 'abc' }, 'ba<>"&r', GT_ESCAPEVAL | GT_CLOSETAG));
is ('<foo a="abc">ba&lt;&gt;&quot;&amp;r</foo>' . "\n", $H->foo({ a => 'abc' }, 'ba<>"&r', GT_ESCAPEVAL | GT_ADDNEWLINE));

is ('<foo>', $E->foo() );
is ('<foo />', $E->foo({ _gtflags => GT_CLOSETAG }) );
is ('<foo a="abc">', $E->foo({ a => 'abc' }) );
is ('<foo abc="abc">', $E->foo({ AbC => 'abc' }) );
is ('<foo abc="abc" />', $E->foo({ AbC => 'abc', _gtflags => GT_CLOSETAG }) );
is ('<foo a="abc">bar</foo>', $E->foo({ a => 'abc' }, 'bar') );
is ('<foo a="abc">bar</foo>' . "\n", $E->foo({ a => 'abc', _gtflags => GT_ADDNEWLINE }, 'bar') );
is ('<foo a="abc">ba<>"&r</foo>', $E->foo({ a => 'abc' }, \'ba<>"&r') );
is ('<foo a="abc">ba&lt;&gt;&quot;&amp;r</foo>', $E->foo({ a => 'abc' }, 'ba<>"&r') );
is ('<foo a="abc" />ba&lt;&gt;&quot;&amp;r</foo>', $E->foo({ a => 'abc', _gtflags => GT_CLOSETAG }, 'ba<>"&r') );
is ('<foo a="abc">ba&lt;&gt;&quot;&amp;r</foo>' . "\n", $E->foo({ a => 'abc', _gtflags => GT_ADDNEWLINE }, 'ba<>"&r') );
is ('<foo a="abc">ba&lt;&gt;&quot;&amp;r</foo>' . "\n", $E->foo({ a => 'abc', _gtflags => GT_ADDNEWLINE, _ehflags => EH_LEAVEKNOWN }, 'ba&lt;&gt;&quot;&amp;r') );

is ('<div>foo</div>' . "\n", $E->div("foo") );
is ('<div>f&lt;o&gt;o</div>' . "\n", $E->div("f<o>o") );
is ('<div>f<o>o</div>' . "\n", $E->div(\"f<o>o") );

is ('<span>foo</span>', $E->span("foo") );
is ('<span>f&lt;o&gt;o</span>', $E->span("f<o>o") );
is ('<span>f<o>o</span>', $E->span(\"f<o>o") );
is ('<span a="b">f<o>o</span>', $E->span({ a => "b" }, \"f<o>o") );
is ('<span a="b">f<o>of&lt;o&gt;of<o>o</span>', $E->span({ a => "b" }, [ \"f<o>o", "f<o>o", \"f<o>o" ]) );
is ('<span a="b">f<o>of&lt;o&gt;of<o>o</span><span a="b">f&lt;o&gt;of<o>o</span>', $E->span({ a => "b" }, [ \"f<o>o", "f<o>o", \"f<o>o" ], [ "f<o>o", \"f<o>o" ]) );

my $res = <<EOF;
<tr><th>row 1 heading with &lt;&gt;&amp; nasties</th>
<td class="someclassforeachrow">column 1</td>
<td class="someclassforeachrow">column <b>2</b> with trusted html</td>
</tr>
<tr><th>row 2 heading with <b>trusted</b> html</th>
<td>column 1 with &lt;&gt;&amp; nasties</td>
<td>column <b>2</b> with trusted html</td>
</tr>
EOF

is ($res,
    $E->tr(
      [
        \$E->th("row 1 heading with <>& nasties"),
        \$E->td( { class => "someclassforeachrow" },
          "column 1",
          \"column <b>2</b> with trusted html",
        )
      ], [
        \$E->th(\"row 2 heading with <b>trusted</b> html"),
        \$E->td(
          "column 1 with <>& nasties",
          \"column <b>2</b> with trusted html",
        )
      ]
    )
);
