package HTML::GenerateUtil;

use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

# This allows declaration	use HTML::GenerateUtil ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = (
  'all' => [ qw(
    escape_html generate_attributes generate_tag escape_uri
    EH_INPLACE EH_LFTOBR EH_SPTONBSP EH_LEAVEKNOWN
    GT_ESCAPEVAL GT_ADDNEWLINE GT_CLOSETAG
    EU_INPLACE 
    $H a div span label ul ol li h1 h2 h3 h4
  ) ],
  'consts' => [ qw(
    EH_INPLACE EH_LFTOBR EH_SPTONBSP EH_LEAVEKNOWN
    GT_ESCAPEVAL GT_ADDNEWLINE GT_CLOSETAG
    EU_INPLACE
  ) ]
);

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '1.11';

our $H = 'HTML::GenerateUtil';

require XSLoader;
XSLoader::load('HTML::GenerateUtil', $VERSION);

use constant EH_INPLACE => 1;
use constant EH_LFTOBR => 2;
use constant EH_SPTONBSP => 4;
use constant EH_LEAVEKNOWN => 8;

use constant GT_ESCAPEVAL => 1;
use constant GT_ADDNEWLINE => 2;
use constant GT_CLOSETAG => 4;

use constant EU_INPLACE => 1;

# Preloaded methods go here.

my $escape_all = '"#$%&+,/:;<=>?@[]^`{}|\\' . "\x7f";
my $escape_lite = '"$+,/:;<=>@[]^`{}|\\' . "\x7f";

sub escape_uri { return escape_uri_internal($_[0], $_[2] || $escape_all, $_[1] || 0) }
sub escape_uri_lite { return escape_uri_internal($_[0], $_[2] || $escape_lite, $_[1] || 0) }

# If an unknown function is called, fill in some parameters and
# call generate_tag
# e.g. 
#                 font( $html )  
#      maps to    generate_tag('font',undef,$html, 0 )
#                 font( { size => 1 }, $html )  
#      maps to    generate_tag('font',{ size => 1},$html, 0 )
#                 font( $html, GT_ADDNEWLINE )  
#      maps to    generate_tag('font',{ size => 1},$html, GT_ADDNEWLINE )
sub AUTOLOAD {

  # assume the function name is the tag name
  my $Tag = our $AUTOLOAD;
  $Tag =~ s{.*::}{};

  # if the function was called on the class name, strip out the class name
  shift if $_[0] eq $H;

  # if the first parameter was not a ref, assume no attributes passed,
  # so we use an empty attr list 
  unshift @_, undef unless ($_[0] && ref($_[0]));

  # Use the tag as the first parameter
  unshift @_, lc $Tag;

  # If no flags were specified, set to 0
  $_[3] ||= 0;

  goto &generate_tag;
}

1;

__END__

=head1 NAME

HTML::GenerateUtil - Routines useful when generating HTML output

=head1 SYNOPSIS

  use HTML::GenerateUtil qw(escape_html generate_attributes generate_tag escape_uri :consts $H div);

  my $Html = "text < with > things & that need \x{1234} escaping";
  $Html = escape_html($Html);

  ... or ...

  escape_html($Html, EH_INPLACE);

  ... also ...

  my $Attr = generate_attributes({ href => 'http://...', title => 'blah' });
  $Html = "<a $Attr>$Html</a>";

  ... but even better ...

  $Html = generate_tag('a', { href => 'http://...', title => 'blah' }, $Html, 0);

  ... also you might want something like ...

  my $URI = 'http://host/?' . join ";", map { $_ => escape_uri($Params{$_}) } keys %Params;
  $Html = generate_tag('a', { href => $URI }, $Html, 0);

  ... you can shortcut that by importing a function, or using the autoloading $H object ...

  div({ class => [ qw(a b) ] }, "div content");
  $H->a({ href => $URI  }, "text", GT_ADDNEWLINE);

=head1 DESCRIPTION

Provides a number of functions that make generating HTML output
easier and faster. All written in XS for speed.

=head1 CONTEXT

When creating a web application in perl, you've got a couple of main choices on how
to actually generate the HTML that gets output:

=over 4

=item *

Programatically generating the HTML in perl

=item *

Using some template system for the HTML and inserting the data
calculated in perl as appropriate

=back

Your actual application, experience and environment will generally determine
which is the best way to.

If you go the programatic route, then you generally need some way of
generating the actual HTML output in perl. Again, there's generally a couple
of ways of doing this.

=over 4

=item *

Just joining together text strings in perl as appropriate.

  Eg. $link = "<a href="$ref">$text</a>";

=item *

Or using some function module like CGI

  Eg. $line = a({ href => $ref }, $text);

=item *

More complex object systems like HTML::Table

=back

The first seems easy, but it gets harder when you have to manually escape
each string to avoid placing special HTML chars (eg E<lt>, etc) in strings
like $text above.

With the CGI, most of this is automatically taken care of, and most
strings are automatically escaped to replace special HTML chars with
their entity equivalents.

While this is nice, CGI is written in pure perl, and can end up being a
bit slow, especially if you already have a fast system that generates
pages very heavy in tags (eg lots of table elements, links, etc)

That's where this module comes it. It provides functions useful for
escaping html and generating HTML tags, but it's all written in XS to
be very fast. It's also fully UTF-8 aware.

=head1 FUNCTIONS

=over 4

=item C<escape_html($Str [, $Mode ])>

Escapes the contents of C<$Str> to change the chars
[<>&"] to '&lt;', '&gt;', '&amp;' and '&quot;' repectively.

C<$Mode> is an optional bit field with the additional options or'd together:

=over 4

=item *

C<EH_INPLACE> - modify in-place, otherwise return new copy

=item *

C<EH_LFTOBR> - convert \n to <br>

=item *

C<EH_SPTONBSP> - convert '  ' to ' &nbsp;'

=item *

C<EH_LEAVEKNOWN> - if & is followed by text that looks like an
entity reference (eg &#1234; or &#x1ab2; or &nbsp;) then it's
left unescaped

=back

Useful for turning text into similar to <pre> form without
actually being in <pre> tags

=item C<generate_attributes($HashRef)>

Turns the contents of C<$HashRef> of the form:

  {
    aaa => 'bbb',
    ccc => undef
  }

Into a string of the form:

  q{aaa="bbb" ccc}

Useful for generating HTML tags. The I<values> of each hash
entry are escaped with escape_html() before being added
to the final string.

If you want to use a raw value unescaped, pass it as a
scalar ref with a single item. Eg.

  {
    aaa => \'<blah>',
    bbb => '<blah>'
  }

Is turned into:

  q{aaa="<blah>" bbb="&lt;blah&gt;"}

If the value is an array ref, then the individual items
are joined together with a space separator. Eg.

  {
    class => [ 'class1', 'class2', \'<blah>' ],
    aaa => 'bbb'
  }

Is turned into:

  q{aaa="bbb" class="class1 class2 <blah>"}

If the value is a hash ref, then the individual keys
are joined together with a space separator. Eg.

  {
    class => { class1 => 1, class2 => 2 ],
    aaa => 'bbb'
  }

Is turned into:

  q{aaa="bbb" class="class2 class1"}

Keys are always escaped since you can't have a scalar
reference as a key.

=item C<generate_tag($Tag, $AttrHashRef, $Value, $Mode)>

Creates an HTML tag of the basic form:

  <$Tag %$AttrHashRef>$Value</$Tag>

If C<$AttrHashRef> is C<undef>, then no attributes are created.
Otherwise C<generate_attributes()> is called to stringify
the hash ref.

If C<$Value> is C<undef>, then no C<$Value> is included, and
no E<lt>/$TagE<gt> is added.

C<$Mode> is a bit field with the additional options:

=over 4

=item *

C<GT_ESCAPEVAL> - call escape_html on $Value

=item *

C<GT_ADDNEWLINE> - append \n to output of string

=item *

C<GT_CLOSETAG> - close the tag (eg <tag />). This should really
only be used when C<$Value> is undef, otherwise you'll end
up with something like C<E<lt>tag /E<gt>valueE<lt>/tagE<gt>>,
which is probably not what you want

=back

=item C<escape_uri($Uri, [ $Mode, $EscapeChars ])>

Escape unsafe characters in a uri.

This escapes all characters not in the unreserved character set.
As a regexp that is:

  [^A-Za-z0-9\-_.!~*'()]

or

  [\x00-\x1F "#$%&+,/:;<=>?@\[\]^`{}|\\\x7f-\xff];

Some other things to note:

=over 4

=item *

The escaping assumes all strings with high-chars are utf-8 strings. That
is it first turns off any utf-8 bit on the string, and then encodes each
byte to it's corresponding octet.

=item *

When encoding a uri with parameters, you'll probably want to encode each
parameter first and then join it to the final string, something like:

  my %uri_params = ( ... )
  my $uri = "http://hostname.com/somepath/?" .
    join ";",
    map { $_ . "=" . escape_uri($uri_params{$_}) } 
    keys %uri_params;

Assuming your keys don't have any unreserved characters in them, a common
practice in many peoples design.

Doing something like:

  my $uri = escape_uri("http://hostname.com/somepath/?a=p1");

Will escape the '?', not giving you what you expect at the other end.

=back

C<$Mode> is a bit field with the additional options:

=over 4

=item *

C<EU_INPLACE> - modify in-place, otherwise return new copy

=back

=back

=cut

=head1 BUGS AND LIMITATIONS

The EH_LEAVEKNOWN option is just heuristic, and accepts anything
that even looks like an entity reference, even if it isn't a
correct one. I'm not sure if this is a securit issue or not.

=cut

=head1 SEE ALSO

L<Apache::Util>, L<HTML::Entities>, L<CGI>

Latest news/details can also be found at:

L<http://cpan.robm.fastmail.fm/htmlgenerateutil/>

Available on github at:

L<https://github.com/robmueller/html-generateutil/>

=cut

=head1 AUTHOR

Rob Mueller E<lt>cpan@robm.fastmail.fmE<gt>

=cut

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004-2011 by Opera Software Australia Pty Ltd

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

