package Judoon::Spreadsheet;

=pod

=encoding utf8

=head1 NAME

Judoon::Spreadsheet - spreadsheet parsing module

=head1 SYNOPSIS

 use Judoon::Spreadsheet;
 my $data = Judoon::Spreadsheet::read_spreadsheet($filehandle, 'xls');

=head1 DESCRIPTION

This module is currently a thin wrapper around L<Spreadsheet::Read>
that takes a filehandle and optional parser specification (i.e. file
type, 'xls', 'csv', 'xlsx') and returns a data structure representing
that spreadsheet.

=cut

use Moo;
use MooX::Types::MooseLike::Base qw(Str ArrayRef HashRef);

use Clone qw(clone);
use Spreadsheet::Read ();


=head1 ATTRIBUTES

=cut

has filename   => (is => 'ro',);
has filehandle => (is => 'ro',);
has filetype   => (is => 'ro',);
has content    => (is => 'ro',);

around BUILDARGS => sub {
    my ($orig, $class, @args) = @_;

    my $args = $class->$orig(@args);
    my $count = grep {exists $args->{$_}} qw(filename filehandle content);
    my $failure = $count < 1 ? "One of 'filename','filehandle','content' is required in constructor to Judoon::Spreadsheet"
        : $count > 1 ? "Only one of 'filename','filehandle','content' is allowed in constructor to Judoon::Spreadsheet"
            : q{};
    die $failure if ($failure);

    return $args;
};

has spreadsheet_read_args => (is => 'lazy', isa => HashRef,);
sub _build_spreadsheet_read_args {
    my ($self) = @_;
    return {attr => 1, clip =>1,};
}

has spreadsheet => (is => 'lazy', isa => ArrayRef,);
sub _build_spreadsheet {
    my ($self) = @_;

    my @source_args;
    if ($self->filename) {
        push @source_args, $self->filename;
    }
    elsif ($self->content) {
        push @source_args, $self->content;
    }
    else {
        push @source_args, $self->filehandle, 'parser',
            ($self->filetype // 'xls');
    }

    return Spreadsheet::Read::ReadData(
        @source_args, %{$self->spreadsheet_read_args},
    ) or die "Unable to read spreadsheet: $!";
}


has orig_data => (is => 'lazy', isa => ArrayRef[ArrayRef],);
sub _build_orig_data {
    my ($self) = @_;
    return [Spreadsheet::Read::rows($self->spreadsheet->[1])];
}

has workbook_meta => (is => 'lazy', isa => HashRef,);
sub _build_workbook_meta {
    my ($self) = @_;
    return $self->spreadsheet->[0];
}


has data    => (is => 'ro', isa => ArrayRef[ArrayRef], predicate => 1, init_arg => undef, lazy => 1, builder => '_build_data_and_headers',);
has headers => (is => 'ro', isa => ArrayRef,           predicate => 1, init_arg => undef, lazy => 1, builder => '_build_data_and_headers',);
sub _build_data_and_headers {
    my ($self) = @_;
    my $data = clone($self->orig_data);
    my $headers = shift @$data;
    $self->{headers} = $headers;
    $self->{data}    = $data;
}


=head1 METHODS

=cut

sub worksheet_name {
    my ($self) = @_;
    return $self->spreadsheet->[1]{label};
}


sub nbr_rows {
    my ($self) = @_;
    return scalar @{$self->data};
}

sub nbr_columns {
    my ($self) = @_;
    return scalar @{$self->data->[0]};
}

1;
__END__
