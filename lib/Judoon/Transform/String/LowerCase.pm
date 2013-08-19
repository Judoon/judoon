package Judoon::Transform::String::LowerCase;

use Moo;

with 'Judoon::Transform::Role::Base',
     'Judoon::Transform::Role::OneInput';

sub result_data_type      { return 'CoreType_Text'; }

sub apply_batch {
    my ($self, $data) = @_;
    return [map {lc} @$data];
}

1;
__END__

=pod

=encoding utf8

=for stopwords lowercased

=head1 NAME

Judoon::Transform::String::LowerCase - Lowercase input text

=head1 METHODS

=head2 result_data_type

C<CoreType_Text>

=head2 apply_batch

Transform all input text into lowercased text.

=cut
