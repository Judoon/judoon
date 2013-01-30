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



1;
__END__
