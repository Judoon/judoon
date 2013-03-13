package Judoon::Web::Plugin::ErrorCatcher::Email;

=pod

=encoding utf8

=head1 NAME

Judoon::Web::Plugin::ErrorCatcher::Email - wrap CP::ErrorCatcher::Email to provide extra info

=head1 SYNOPSIS

 package Judoon::Web;

 __PACKAGE__->config(
     'Plugin::ErrorCatcher' => {
          emit_module => 'Judoon::Web::Plugin::ErrorCatcher::Email',
     },
 );

=head1 DESCRIPTION

Wrap the C<emit()> function of
L</Catalyst::Plugin::ErrorCatcher::Email> to provide an error summary
at the top of the email, similar to what's show on the development
debug page.

=cut

use Moose;
use MooseX::NonMoose;
use namespace::autoclean;

extends 'Catalyst::Plugin::ErrorCatcher::Email';

use Safe::Isa;


=head1 METHODS

=head2 emit

See L</DESCRIPTION>.

=cut

around emit => sub {
    my ($orig, $class, $c, $output) = @_;

    my @error_summary;
    for my $error (@{ $c->error }) {
        my ($error_type, $error_msg)
            = !blessed($error)                ? ('Plain perl', $error)
            : $error->$_DOES('Judoon::Error') ? (ref($error), $error->message)
            :                                   (ref($error), (split /\n/, "$error")[0]);
        push @error_summary, [$error_type, $error_msg];
    }

    my $cnt = 1;
    my $new_output = qq{Error Summary:\n----\n\n};

    $new_output .= join "\n\n",
        map {$cnt++ . ": $_->[0]\n\t$_->[1]"} @error_summary;
    $new_output .= "\n\nOriginal Summary:\n----\n\n" . $output;

    return $class->$orig($c, $new_output);
};



__PACKAGE__->meta->make_immutable;
1;
__END__
