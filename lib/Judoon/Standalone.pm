package Judoon::Standalone;

use Moo;

use Archive::Builder;
use File::Temp qw(tempfile);
use Path::Class qw(dir);
use Template;

=head1 ATTRIBUTES

=cut

has 'page' => (is => 'ro', required => 1,);

has standalone_index => (is => 'lazy',);
sub _build_standalone_index { return 'index.html'; }
has standalone_db => (is => 'lazy',);
sub _build_standalone_db { return 'cgi-bin/database.tab'; }


has template_dir => (is => 'lazy',);
sub _build_template_dir { return dir('root/src/standalone'); }
has skeleton_dir => (is => 'lazy',);
sub _build_skeleton_dir { return $_[0]->template_dir->subdir('skeleton'); }
has index_tmpl => (is => 'lazy',);
sub _build_index_tmpl { return $_[0]->template_dir->file('index.tt2'); }


has archive => (is => 'lazy',);
sub _build_archive { return Archive::Builder->new; }
has archive_section => (is => 'lazy',);
sub _build_archive_section { return $_[0]->archive->new_section('judoon'); }

has tt => (is => 'lazy',);
sub _build_tt { return Template->new; }


=head1 METHODS

=cut

sub archive_error { return $_[0]->archive->errstr; }

sub build {
    my ($self) = @_;
    $self->add_skeleton();
    $self->fill_index_template();
    $self->export_database();
    die $self->archive_arror if ($self->archive_error);
    return;
}

sub compress {
    my ($self, $type) = @_;
    my $archive_compressed = $self->archive->archive($type || 'zip')
        or die $self->archive_error;
    my ($fh, $filename) = tempfile(SUFFIX => ".$type", UNLINK => 1,);
    $archive_compressed->save( $filename ) or die $self->archive_error;
    return $filename;
}

sub add_skeleton {
    my ($self) = @_;

    $self->skeleton_dir->recurse( callback => sub {
        my ($child) = @_;
        if (not $child->is_dir) {
            my $child_path = $child->relative($self->skeleton_dir);
            $self->archive_section->new_file(
                $child_path->stringify, 'file', $child->stringify
            ) or die "($child_path|$child): " . $self->archive_error;
        }
    } );

    # remove plugins.js; download uses minified version
    $self->archive_section->remove_file('js/plugins.js');
}

sub fill_index_template {
    my ($self) = @_;
    $self->archive_section->new_file(
        'index.html', 'template', $self->tt, $self->index_tmpl->stringify,
        {page => $self->page},
    ) or die "Cannot template? " . $self->archive->errstr;
}

sub export_database {
    my ($self) = @_;
    $self->archive_section->new_file(
        $self->standalone_db, 'string', $self->page->dataset->as_raw
    );
}

1;
__END__
