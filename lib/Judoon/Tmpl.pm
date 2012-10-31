package Judoon::Tmpl;

=pod

=encoding utf-8

=head1 NAME

Judoon::Tmpl - Object representing a template

=head1 SYNOPSIS

 use Judoon::Tmpl;

 my $template = Judoon::Tmpl->new_from_jstmpl('foo{{=bar}}baz');
 my @variables = $template->get_variables(); # 'bar'
 my $serialized = $template->to_native;
 my $javascript = $template->to_jstmpl;

=cut

use Moo;
use MooX::Types::MooseLike::Base qw(ArrayRef ConsumerOf InstanceOf);

use Judoon::Tmpl::Util ();


has nodes => (
    is  => 'lazy',
    isa => ArrayRef[ConsumerOf('Judoon::Tmpl::Node::Base')],
);
sub _build_nodes { return []; }

sub get_nodes  { return @{ shift->nodes }; }
sub node_count { return scalar shift->get_nodes; }
sub node_types { return map {$_->type} shift->get_nodes; }


=head1 Alternative Constructors

=head2 new_from_jstmpl

=cut

sub new_from_jstmpl {
    my ($class, $template) = @_;
    die "Don't call new_from_jstmpl() on an object" if (ref($class));
    return $class->new({
        nodes => [Judoon::Tmpl::Util::jstmpl_to_nodes($template)],
    });
}

sub new_from_native {
    my ($class, $template) = @_;
    die "Don't call new_from_native() on an object" if (ref($class));
    return $class->new({
        nodes => [Judoon::Tmpl::Util::native_to_nodes($template)],
    });
}

sub new_from_data {
    my ($class, $nodelist) = @_;
    die "Don't call new_from_native() on an object" if (ref($class));
    return $class->new({
        nodes => [Judoon::Tmpl::Util::data_to_nodes($nodelist)],
    });
}

=head2 B<C< get_variables >>

Get a list of variable names used in our template.

=cut

sub get_variables {
    my ($self) = @_;
    return map {$_->name} grep {$_->type eq 'variable'} map {$_->decompose}
        $self->get_nodes;
}


sub to_jstmpl {
    my ($self) = @_;
    return Judoon::Tmpl::Util::nodes_to_jstmpl($self->get_nodes);
}


sub to_native {
    my ($self) = @_;
    return Judoon::Tmpl::Util::nodes_to_native($self->get_nodes);
}


sub to_data {
    my ($self) = @_;
    return Judoon::Tmpl::Util::nodes_to_data($self->get_nodes);
}

1;
__END__
