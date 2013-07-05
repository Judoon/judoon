package Judoon::API::Resource::PageColumn;

use Moo;

extends 'Web::Machine::Resource';
with 'Judoon::Role::JsonEncoder';
with 'Judoon::API::Resource::Role::Item';

use Judoon::Tmpl;

around update_resource => sub {
    my $orig = shift;
    my $self = shift;
    my $data = shift;

    my $jstmpl = $data->{template};
    my $tmpl   = Judoon::Tmpl->new_from_jstmpl($jstmpl);
    $data->{template} = $tmpl;
    return $self->$orig($data);
};

1;
__END__
