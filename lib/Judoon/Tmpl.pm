package Judoon::Tmpl;

use Moo;
use MooX::Types::MooseLike::Base qw(ArrayRef ConsumerOf InstanceOf);

use Judoon::Tmpl::Util ();


has nodes => (is => 'lazy', isa => ArrayRef[ConsumerOf('Judoon::Tmpl::Node::Base')],);
sub _build_nodes { return []; }

sub get_nodes { return @{ shift->nodes }; }
sub node_count { return scalar shift->get_nodes; }
sub node_types { return map {$_->type} shift->get_nodes; }

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
    return Judoon::Tmpl::Util::nodes_to_jquery($self->get_nodes);
}


sub add_text {
    my ($self, $value, $formatting) = @_;
    push @{$self->nodes}, Judoon::Tmpl::Node::Text->new({
        value => $value, formatting => ($formatting // []),
    });
    return $self;
}

sub add_variable {
    my ($self, $name, $formatting) = @_;
    push @{$self->nodes}, Judoon::Tmpl::Node::Variable->new({
        name => $name, formatting => ($formatting // []),
    });
    return $self;
}

sub add_newline {
    my ($self, $name) = @_;
    push @{$self->nodes}, Judoon::Tmpl::Node::Newline->new();
    return $self;
}

sub add_link {
    my ($self, $link_args, $formatting) = @_;
    push @{$self->nodes}, Judoon::Tmpl::Node::Variable->new({
        %$link_args, formatting => ($formatting // []),
    });
    return $self;
}


1;
__END__
