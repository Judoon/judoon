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


has archive_name => (is => 'lazy',);
sub _build_archive_name { return 'judoon'; }
has archive => (is => 'lazy',);
sub _build_archive {
    my ($self) = @_;
    my $archive = Archive::Builder->new;
    my $archive_section = $archive->new_section($self->archive_name);

    # add static files
    $self->skeleton_dir->recurse( callback => sub {
        my ($child) = @_;
        if (not $child->is_dir) {
            my $child_path = $child->relative($self->skeleton_dir);
            $archive_section->new_file(
                $child_path->stringify, 'file', $child->stringify
            ) or die "($child_path|$child): " . $archive->errstr;
        }
    } );

    # mark data.cgi as executable, so permissions work
    $archive_section->file('cgi-bin/data.cgi')->executable;

    # remove plugins.js; download uses minified version
    $archive_section->remove_file('js/plugins.js');

    # add index
    $archive_section->new_file(
        'index.html', 'template', $self->tt, $self->index_tmpl->stringify,
        {page => $self->page},
    ) or die "Cannot template? " . $archive->errstr;

    # add database
    $archive_section->new_file(
        $self->standalone_db, 'string', $self->page->dataset->as_raw({shortname => 1})
    );

    die $archive->errstr if ($archive->errstr);
    return $archive;
}


has tt => (is => 'lazy',);
sub _build_tt { return Template->new; }


=head1 METHODS

=cut

sub compress {
    my ($self, $type) = @_;
    my $archive_compressed = $self->archive->archive($type || 'zip')
        or die $self->archive->errstr;
    my ($fh, $filename) = tempfile(SUFFIX => ".$type", UNLINK => 1,);
    $archive_compressed->save( $filename ) or die $self->archive->errstr;
    return $filename;
}


1;
__END__
