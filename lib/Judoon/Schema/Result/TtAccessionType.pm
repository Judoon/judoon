package Judoon::Schema::Result::TtAccessionType;

=pod

=encoding utf8

=head1 NAME

Judoon::Schema::Result::TtAccessionType

=cut

use Moo;
extends 'Judoon::Schema::Result';

__PACKAGE__->table("tt_accession_types");
__PACKAGE__->add_columns(
    id => {
        data_type         => "integer",
        is_auto_increment => 1,
        is_nullable       => 0,
    },
    accession_type => {
        data_type      => "text",
        is_nullable    => 0,
    },
    accession_domain => {
        data_type      => "text",
        is_nullable    => 0,
    },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint(
    accession_type_unique => [qw(accession_type)],
);
__PACKAGE__->has_many(
    ds_columns => "::DatasetColumn",
    { "foreign.accession_type_id" => "self.id" },
);



1;
__END__
