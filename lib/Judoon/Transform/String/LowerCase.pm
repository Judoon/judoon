package Judoon::Transform::String::LowerCase;

use Moo;

with 'Judoon::Transform::Role::Base',
     'Judoon::Transform::Role::OneInput';

sub result_data_type      { return 'text'; }
sub result_accession_type { return undef;  }

sub apply_batch {
    my ($self, $data) = @_;
    return [map {lc} @$data];
}

1;
__END__
