package t::Role::HtmlFixtures;

=pod

=encoding utf-8

=head1 NAME

t::Role::HtmlFixtures - provide standard HTML scrubbing fixtures

=head1 DESCRIPTION

Test files using L</Test::Roo> can consume this role to get sets of
standard data for testing HTML scrubbing ability

=cut

use Data::Section::Simple qw(get_data_section);
use List::Util qw();
use Types::Standard qw(HashRef);

use Test::Roo::Role;


my @fixture_types = qw(tainted scrubbed_string scrubbed_block);
my @fixture_sets  = qw(
    basic basic_entity simple_html scary_html simple_block
    encoded_scary long_block
    allinlinetags allblocktags badtags
);



=head1 ATTRIBUTES

=head2 html_fixtures / _build_html_fixtures

Useful fixture sets for testing HTML scrubbing.

=cut

has html_fixtures => (
    is  => 'lazy',
    isa => HashRef,
);
sub _build_html_fixtures {
    my ($self) = @_;

    my %fixtures;
    for my $set (@fixture_sets) {
        for my $type (@fixture_types) {
            $fixtures{$set}{$type} = get_data_section("${set}-${type}");
            die "Missing HTML fixture: ${set}-${type}"
                unless (defined $fixtures{$set}{$type});
            chomp $fixtures{$set}{$type};
        }
    }

    return \%fixtures;
}


=head1 METHODS

=head2 get_html_fixture( $fixture_name )

Get the fixture called C<$fixture_name> or die screaming.

=head2 add_html_fixture( $fixture_name, $type, $fixture )

Add a new fixture definition to the internal fixtures
dictionary. C<$type> must match one of the entries in
C<@fixture_types>.

=cut

sub get_html_fixture {
    my ($self, $key) = @_;
    return $self->html_fixtures->{$key} or die "No such html fixture: $key";
}

sub add_html_fixture {
    my ($self, $key, $type, $fixture) = @_;
    die "Bad type **$type** passed to add_html_fixtures()"
        unless (List::Util::first {$_ eq $type} @fixture_types);
    $self->html_fixtures->{$key}{$type} = $fixture;
}


1;


__DATA__
@@ basic-tainted
hey
@@ basic-scrubbed_string
hey
@@ basic-scrubbed_block
hey
@@ basic_entity-tainted
hey &amp; hi
@@ basic_entity-scrubbed_string
hey &amp; hi
@@ basic_entity-scrubbed_block
hey &amp; hi
@@ simple_html-tainted
<em>hey</em>
@@ simple_html-scrubbed_string
<em>hey</em>
@@ simple_html-scrubbed_block
<em>hey</em>
@@ scary_html-tainted
<script>hey</script>
@@ scary_html-scrubbed_string

@@ scary_html-scrubbed_block

@@ simple_block-tainted
<p>hey</p>
@@ simple_block-scrubbed_string
hey
@@ simple_block-scrubbed_block
<p>hey</p>
@@ encoded_scary-tainted
&lt;script&gt;hey&lt;/script&gt;
@@ encoded_scary-scrubbed_string
&lt;script&gt;hey&lt;/script&gt;
@@ encoded_scary-scrubbed_block
&lt;script&gt;hey&lt;/script&gt;
@@ long_block-tainted
<p><strong>Mogilner A</strong> , Edelstein-Keshet L. Regulation of actin dynamics in rapidly moving cells: a quantitative analysis. Biophys J. 2002;83(3):1237-58.</p>
@@ long_block-scrubbed_string
<strong>Mogilner A</strong> , Edelstein-Keshet L. Regulation of actin dynamics in rapidly moving cells: a quantitative analysis. Biophys J. 2002;83(3):1237-58.
@@ long_block-scrubbed_block
<p><strong>Mogilner A</strong> , Edelstein-Keshet L. Regulation of actin dynamics in rapidly moving cells: a quantitative analysis. Biophys J. 2002;83(3):1237-58.</p>
@@ allinlinetags-tainted
<a>a</a><abbr>abbr</abbr> <b>b</b> <bdi>bdi</bdi> <bdo>bdo</bdo>
<cite>cite</cite> <code>code</code> <del>del</del> <dfn>dfn</dfn>
<em>em</em> <i>i</i> <ins>ins</ins> <kbd>kbd</kbd> <mark>mark</mark>
<meter>meter</meter> <q>q</q> <s>s</s> <samp>samp</samp>
<small>small</small> <span>span</span> <strong>strong</strong>
<sub>sub</sub> <sup>sup</sup> <time>time</time> <u>u</u>
<var>var</var> <wbr>
@@ allinlinetags-scrubbed_string
<a>a</a><abbr>abbr</abbr> <b>b</b> <bdi>bdi</bdi> <bdo>bdo</bdo>
<cite>cite</cite> <code>code</code> <del>del</del> <dfn>dfn</dfn>
<em>em</em> <i>i</i> <ins>ins</ins> <kbd>kbd</kbd> <mark>mark</mark>
<meter>meter</meter> <q>q</q> <s>s</s> <samp>samp</samp>
<small>small</small> <span>span</span> <strong>strong</strong>
<sub>sub</sub> <sup>sup</sup> <time>time</time> <u>u</u>
<var>var</var> <wbr>
@@ allinlinetags-scrubbed_block
<a>a</a><abbr>abbr</abbr> <b>b</b> <bdi>bdi</bdi> <bdo>bdo</bdo>
<cite>cite</cite> <code>code</code> <del>del</del> <dfn>dfn</dfn>
<em>em</em> <i>i</i> <ins>ins</ins> <kbd>kbd</kbd> <mark>mark</mark>
<meter>meter</meter> <q>q</q> <s>s</s> <samp>samp</samp>
<small>small</small> <span>span</span> <strong>strong</strong>
<sub>sub</sub> <sup>sup</sup> <time>time</time> <u>u</u>
<var>var</var> <wbr>
@@ allblocktags-tainted
<a>a</a><abbr>abbr</abbr> <b>b</b> <bdi>bdi</bdi> <bdo>bdo</bdo>
<cite>cite</cite> <code>code</code> <del>del</del> <dfn>dfn</dfn>
<em>em</em> <i>i</i> <ins>ins</ins> <kbd>kbd</kbd> <mark>mark</mark>
<meter>meter</meter> <q>q</q> <s>s</s> <samp>samp</samp>
<small>small</small> <span>span</span> <strong>strong</strong>
<sub>sub</sub> <sup>sup</sup> <time>time</time> <u>u</u>
<var>var</var> <wbr>

<address>address</address> <article>article</article>
<aside>aside</aside> <blockquote>blockquote</blockquote> <br>br</br>
<caption>caption</caption> <col>col</col>
<colgroup>colgroup</colgroup> <dd>dd</dd> <details>details</details>
<div>div</div> <dl>dl</dl> <dt>dt</dt>
<figcaption>figcaption</figcaption> <figure>figure</figure>
<footer>footer</footer> <h1>h1</h1> <h2>h2</h2> <h3>h3</h3>
<h4>h4</h4> <h5>h5</h5> <h6>h6</h6> <header>header</header>
<hr>hr</hr> <img>img</img> <li>li</li> <nav>nav</nav> <ol>ol</ol>
<p>p</p> <pre>pre</pre> <section>section</section>
<summary>summary</summary> <table>table</table> <tbody>tbody</tbody>
<td>td</td> <tfoot>tfoot</tfoot> <th>th</th> <thead>thead</thead>
<tr>tr</tr> <ul>ul</ul>
@@ allblocktags-scrubbed_string
<a>a</a><abbr>abbr</abbr> <b>b</b> <bdi>bdi</bdi> <bdo>bdo</bdo>
<cite>cite</cite> <code>code</code> <del>del</del> <dfn>dfn</dfn>
<em>em</em> <i>i</i> <ins>ins</ins> <kbd>kbd</kbd> <mark>mark</mark>
<meter>meter</meter> <q>q</q> <s>s</s> <samp>samp</samp>
<small>small</small> <span>span</span> <strong>strong</strong>
<sub>sub</sub> <sup>sup</sup> <time>time</time> <u>u</u>
<var>var</var> <wbr>

address article
aside blockquote br
caption col
colgroup dd details
div dl dt
figcaption figure
footer h1 h2 h3
h4 h5 h6 header
hr img li nav ol
p pre section
summary table tbody
td tfoot th thead
tr ul
@@ allblocktags-scrubbed_block
<a>a</a><abbr>abbr</abbr> <b>b</b> <bdi>bdi</bdi> <bdo>bdo</bdo>
<cite>cite</cite> <code>code</code> <del>del</del> <dfn>dfn</dfn>
<em>em</em> <i>i</i> <ins>ins</ins> <kbd>kbd</kbd> <mark>mark</mark>
<meter>meter</meter> <q>q</q> <s>s</s> <samp>samp</samp>
<small>small</small> <span>span</span> <strong>strong</strong>
<sub>sub</sub> <sup>sup</sup> <time>time</time> <u>u</u>
<var>var</var> <wbr>

<address>address</address> <article>article</article>
<aside>aside</aside> <blockquote>blockquote</blockquote> <br>br</br>
<caption>caption</caption> <col>col</col>
<colgroup>colgroup</colgroup> <dd>dd</dd> <details>details</details>
<div>div</div> <dl>dl</dl> <dt>dt</dt>
<figcaption>figcaption</figcaption> <figure>figure</figure>
<footer>footer</footer> <h1>h1</h1> <h2>h2</h2> <h3>h3</h3>
<h4>h4</h4> <h5>h5</h5> <h6>h6</h6> <header>header</header>
<hr>hr</hr> <img>img</img> <li>li</li> <nav>nav</nav> <ol>ol</ol>
<p>p</p> <pre>pre</pre> <section>section</section>
<summary>summary</summary> <table>table</table> <tbody>tbody</tbody>
<td>td</td> <tfoot>tfoot</tfoot> <th>th</th> <thead>thead</thead>
<tr>tr</tr> <ul>ul</ul>
@@ badtags-tainted
<html><head><base><link><meta><title>quack</title></head><body>
<p>invalid</p>
<script>script</script><noscript>noscript</noscript><iframe>iframe</iframe><style>style</style>
<p>obsolete</p>
<acronym>acronym</acronym><applet>applet</applet><basefont>basefont</basefont>
<bgsound>bgsound</bgsound><big>big</big><blink>blink</blink><center>center</center>
<dir>dir</dir><font>font</font><frame>frame</frame><frameset>frameset</frameset>
<hgroup>hgroup</hgroup><isindex>isindex</isindex><listing>listing</listing>
<plaintext>plaintext</plaintext><marquee>marquee</marquee><nobr>nobr</nobr><noframes>noframes</noframes>
<spacer>spacer</spacer><strike>strike</strike>
<tt>tt</tt><xmp>xmp</xmp>
<p>advanced</p>
<area>area</area><audio>audio</audio><canvas>canvas</canvas>
<content>content</content><data>data</data><decorator>decorator</decorator>
<element>element</element><embed>embed</embed><keygen>keygen</keygen>
<main>main</main><map>map</map><menu>menu</menu><menuitem>menuitem</menuitem>
<object>object</object><param>param</param><progress>progress</progress>
<rp>rp</rp><rt>rt</rt><ruby>ruby</ruby><shadow>shadow</shadow>
<source>source</source><template>template</template><track>track</track>
<video>video</video>
<p>form</p>
<button>button</button><datalist>datalist</datalist>
<fieldset>fieldset</fieldset><form>form</form><input>input</input>
<label>label</label><legend>legend</legend><optgroup>optgroup</optgroup>
<option>option</option><output>output</output><select>select</select>
<textarea>textarea</textarea>
</body></html>
@@ badtags-scrubbed_string
quack
invalid
noscriptiframe
obsolete
acronymappletbasefont
bgsoundbigblinkcenter
dirfontframeframeset
hgroupisindexlisting
plaintextmarqueenobrnoframes
spacerstrike
ttxmp
advanced
areaaudiocanvas
contentdatadecorator
elementembedkeygen
mainmapmenumenuitem
objectparamprogress
rprtrubyshadow
sourcetemplatetrack
video
form
buttondatalist
fieldsetforminput
labellegendoptgroup
optionoutputselect
textarea

@@ badtags-scrubbed_block
quack
<p>invalid</p>
noscriptiframe
<p>obsolete</p>
acronymappletbasefont
bgsoundbigblinkcenter
dirfontframeframeset
hgroupisindexlisting
plaintextmarqueenobrnoframes
spacerstrike
ttxmp
<p>advanced</p>
areaaudiocanvas
contentdatadecorator
elementembedkeygen
mainmapmenumenuitem
objectparamprogress
rprtrubyshadow
sourcetemplatetrack
video
<p>form</p>
buttondatalist
fieldsetforminput
labellegendoptgroup
optionoutputselect
textarea

@@ placeholder-tainted
@@ placeholder-scrubbed_string
@@ placeholder-scrubbed_block
