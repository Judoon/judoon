package Judoon::Tmpl::Translator;

our $VERSION = '0.001';
use Moose;
use namespace::autoclean;

use Data::Printer;
use Method::Signatures;

use Judoon::Tmpl::Translator::Dialect::Native;
use Judoon::Tmpl::Translator::Dialect::WebWidgets;
use Judoon::Tmpl::Translator::Dialect::JQueryTemplate;
sub dialects { return qw(Native WebWidgets JQueryTemplate); }

has dialect_objects => (
    is => 'ro',
    isa => 'HashRef',
    lazy_build => 1,
);
sub _build_dialect_objects {
    my ($self) = @_;
    my %dialects;
    for my $dialect (dialects()) {
        my $class = "Judoon::Tmpl::Translator::Dialect::$dialect";
        $dialects{$dialect} = $class->new;
    }
    return \%dialects;
}


method translate(:$from!, :$to!, :$template!) {
    die "$from is not a valid dialect" if (not grep {$_ eq $from} dialects());
    die "$to is not a valid dialect"   if (not grep {$_ eq $to} dialects());
    my @native_objs = $self->dialect_objects->{$from}->parse($template);
    return $self->dialect_objects->{$to}->produce(@native_objs);
}



__PACKAGE__->meta->make_immutable;

1;
__END__
