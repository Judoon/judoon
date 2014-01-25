package Judoon::Schema::Role::Result::HasTimestamps;

use Moo::Role;

=pod

=encoding utf8

=head2 register_timestamps

Add C<created> and C<modified> fields to the composing class.

=cut

sub register_timestamps {
    my ($class) = @_;
    $class->add_columns(
        created => {
            data_type     => 'timestamp with time zone',
            is_nullable   => 0,
            set_on_create => 1,
        },
        modified => {
            data_type     => 'timestamp with time zone',
            is_nullable   => 0,
            set_on_create => 1,
            set_on_update => 1,
        },
    );
}



around TO_JSON => sub {
    my $orig = shift;
    my $self = shift;

    my $ret = $self->$orig();
    $ret->{created}  = $self->created . "";
    $ret->{modified} = $self->modified . "";
    return $ret;
};


1;
__END__

=head1 AUTHOR

Fitz ELLIOTT <felliott@fiskur.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by the Rector and Visitors of the
University of Virginia.

This is free software, licensed under:

 The Artistic License 2.0 (GPL Compatible)

=cut
