package Judoon::Schema::Result::TtDscolumnDatatype;

=pod

=encoding utf8

=head1 NAME

Judoon::Schema::Result::TtDscolumnDatatype

=cut

use Judoon::Schema::Candy;
use Moo;

table 'tt_dscolumn_datatypes';

primary_column id => {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
};
unique_column data_type => {
    data_type      => "text",
    is_nullable    => 0,
};


has_many ds_columns => "::DatasetColumn",
    { "foreign.data_type_id" => "self.id" };


1;
__END__
