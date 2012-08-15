package Judoon::Tmpl::Translator;

use Moo;
use MooX::Types::MooseLike::Base qw(HashRef);

use Judoon::Tmpl::Translator::Dialect::Native;
use Judoon::Tmpl::Translator::Dialect::WebWidgets;
use Judoon::Tmpl::Translator::Dialect::JQueryTemplate;
use Method::Signatures;

=pod

=encoding utf8

=head2 dialects

A list of supported dialects

=cut

sub dialects { return qw(Native WebWidgets JQueryTemplate); }


=head2 dialect_objects / _build_dialect_objects

Instantiated ::Tmpl::Dialect objects

=cut

has dialect_objects => (is => 'lazy', isa => HashRef,);
sub _build_dialect_objects {
    my ($self) = @_;
    my %dialects;
    for my $dialect (dialects()) {
        my $class = "Judoon::Tmpl::Translator::Dialect::$dialect";
        $dialects{$dialect} = $class->new;
    }
    return \%dialects;
}


=head2 translate(from => C<$from>, to => C<$to>, template => C<$template>)

Translate C<$template> from the C<$from> dialect to the C<$to> dialect.
C<$template> is a string, C<$to> and C<$from> are the names of dialects,
as found in the L<dialects()> sub.

=cut

method translate(:$from!, :$to!, :$template!) {
    my @native_objects = $self->to_objects(from => $from, template => $template);
    return $self->dialect_objects->{$to}->produce(\@native_objects);
}


=head2 to_objects(from => C<$from>, template => C<$template>)

C<to_objects()> turns template strings in the C<$from> dialect into an
arrayref of L<Judoon::Tmpl::Node> objects.

=cut

method to_objects(:$from!, :$template!) {
    die "$from is not a valid dialect" if (not grep {$_ eq $from} dialects());
    return $self->dialect_objects->{$from}->parse($template);
}


=head2 from_objects(to => C<$to>, objects => C<$objects>)

C<from_objects()> turns an arrayref of L<Judoon::Tmpl::Node> objects into a
template string in the C<$to> dialect.

=cut

method from_objects(:$to!, :$objects!) {
    die "$to is not a valid dialect" if (not grep {$_ eq $to} dialects());
    return $self->dialect_objects->{$to}->produce($objects);
}


1;
__END__
