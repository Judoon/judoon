package Judoon::Tmpl::Translator;

our $VERSION = '0.001';
use Moose;
use namespace::autoclean;

use Data::Printer;
use Judoon::Tmpl::Translator::Dialect::Native;
use Judoon::Tmpl::Translator::Dialect::WebWidgets;
use Judoon::Tmpl::Translator::Dialect::JQueryTemplate;
use Method::Signatures;

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
    die "$to is not a valid dialect"   if (not grep {$_ eq $to} dialects());
    my @native_objects = $self->to_objects(from => $from, template => $template);
    return $self->dialect_objects->{$to}->produce(\@native_objects);
}

method to_objects(:$from!, :$template!) {
    die "$from is not a valid dialect" if (not grep {$_ eq $from} dialects());
    return $self->dialect_objects->{$from}->parse($template);
}

method from_objects(:$to!, :$objects!) {
    die "$to is not a valid dialect" if (not grep {$_ eq $to} dialects());
    return $self->dialect_objects->{$to}->produce($objects);
}


__PACKAGE__->meta->make_immutable;

1;
__END__
