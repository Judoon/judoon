package Judoon::Schema::Result::TtAccessionType;

=pod

=encoding utf8

=head1 NAME

Judoon::Schema::Result::TtAccessionType

=cut

use Judoon::Schema::Candy;
use Moo;

table 'tt_accession_types';

primary_column id => {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
};
unique_column accession_type => {
    data_type      => "text",
    is_nullable    => 0,
};
column accession_domain => {
    data_type      => "text",
    is_nullable    => 0,
};

has_many ds_columns => "::DatasetColumn",
    { "foreign.accession_type_id" => "self.id" };


1;
__END__
