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
use MooX::Types::MooseLike::Base qw(Str Int ArrayRef HashRef);

use Data::UUID;
use Clone qw(clone);
use List::Util ();
use Regexp::Common;
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


sub BUILD {
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

    my $spreadsheet = Spreadsheet::Read::ReadData(
        @source_args, cell => 1, rc => 1, attr => 1, clip => 1, # debug => 8,
    ) or die "Unable to read spreadsheet: $!";

    my $worksheet = $spreadsheet->[1];
    $self->{name} = $worksheet->{label};

    my $data             = [Spreadsheet::Read::rows($worksheet)];
    my $headers          = shift @$data;
    $self->{data}        = $data;
    $self->{nbr_rows}    = scalar @$data;
    $self->{nbr_columns} = scalar @{ $data->[0] };

    my (@fields, %colnames_seen);
    my $colidx = 1;
    for my $header (@$headers) {
        my $shortname = $self->_unique_sqlname( \%colnames_seen, $header );

        my $excel_type = $worksheet->{attr}[$colidx][2]{type};
        my %heuristic_types;
        for my $rowidx (2..$worksheet->{maxrow}) {
            my $data = $worksheet->{cell}[ $colidx ][ $rowidx ];
            next if !defined $data || $data eq '';
            my $type = $data =~ m/^$RE{num}{int}$/  ? 'integer'
                     : $data =~ m/^$RE{num}{real}$/ ? 'numeric'
                     :                                'text';
            $heuristic_types{ $type }++;
        }
        my $heuristic_type = List::Util::first {$heuristic_types{$_}}
            qw(text numeric integer);
        $heuristic_type //= 'text';
        $heuristic_type = 'numeric' if ($heuristic_type eq 'integer');

        my $data_type = $heuristic_type;
        push @fields, {
            name => $header,    shortname => $shortname,
            type => $data_type, excel_type => $excel_type,
            heuristic_type => $heuristic_type,
        };
        $colidx++;
    }
    $self->{fields} = \@fields;
}



has name        => (is => 'ro', init_arg => undef, isa => Str, );
has fields      => (is => 'ro', init_arg => undef, isa => ArrayRef[HashRef],);
has data        => (is => 'ro', init_arg => undef, isa => ArrayRef[ArrayRef],);
has nbr_rows    => (is => 'ro', init_arg => undef, isa => Int, );
has nbr_columns => (is => 'ro', init_arg => undef, isa => Int, );


sub _unique_sqlname {
    my ($self, $seen, $name) = @_;

    # stolen from SQL::Translator::Utils::normalize_name
    # The name can only begin with a-zA-Z_; if there's anything
    # else, prefix with _
    $name =~ s/^([^a-zA-Z_])/_$1/;

    # anything other than a-zA-Z0-9_ in the non-first position
    # needs to be turned into _
    $name =~ tr/[a-zA-Z0-9_]/_/c;

    # All duplicated _ need to be squashed into one.
    $name =~ tr/_/_/s;

    # Trim a trailing _
    $name =~ s/_$//;

    $name = lc $name;

    return $name if (!$seen->{$name}++);

    for my $suffix (map {sprintf '%02d', $_} 1..99) {
        my $new_colname = $name . '_' . $suffix;
        return $new_colname if (!$seen->{$new_colname}++);
    }

    for my $i (0..10) {
        my $uuid = Data::UUID->new->create_str();
        my $uuid_name = $name . '_' . $uuid;
        return $uuid_name if(!$seen->{$uuid_name}++);
    }

    die "absolutely insane.  how can we not generate a unique name for this?";
}


1;
__END__
