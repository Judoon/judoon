package Judoon::Standalone;

=pod

=for stopwords tt

=encoding utf8

=head1 NAME

Judoon::Standalone - create a standalone webpage for data display

=head1 SYNOPSIS

 use Judoon::Standalone;

 my ($page) = $user->pages_rs->all;

 my $standalone = Judoon::Standalone->new({page => $page});
 my $path_to_archive = $standalone->compress('zip');

=head1 DESCRIPTION

This module takes an instance of a L<Judoon::Schema::Result::Page> and
builds an archive that contains the page, its data, a script to query
the data, and all the support images, css, and javascript needed to
display the page.

This archive should be able to be unzipped into a web-accessible
folder and run without modification.  The only requirement is that
perl v5.8 or greater be installed.  The intention is to make
installation as easy as possible for non-technical users.

=cut


use Archive::Builder;
use File::Temp qw(tempfile);
use Judoon::Error::Devel::Foreign;
use Judoon::Table;
use Judoon::TypeRegistry;
use Path::Tiny qw(path);
use Template;

use Moo;
use namespace::clean;
with 'Judoon::Role::JsonEncoder';


=head1 ATTRIBUTES

=head2 page

This attribute is an instance of L<Judoon::Schema::Result::Page> for
which a standalone version should be built. This attribute is required.

=cut

has 'page' => (is => 'ro', required => 1,);

=head2 archive

An instance of L</Archive::Builder> that contains the bundled archive
contents.

=cut

has archive => (is => 'lazy',);


=head2 MINOR ATTRIBUTES

=head3 standalone_index

Name of the index file, relative to the project root. Default:
C<index.html>.

=head3 standalone_db

Path to the database file, relative to the project root. Default:
C<cgi-bin/database.tab>

=head3 standalone_types

Path to the list of data types for each column, relative to the
project root. Default: C<cgi-bin/datatypes.tab>.

=head3 template_dir

L<Path::Tiny> object where the templates are kept.

=head3 skeleton_dir

L<Path::Tiny> object where the static files are kept.

=head3 index_tmpl

L<Path::Tiny> object for the index.html template.

=head3 tt

The L<Template::Toolkit> object.

=head3 archive_name

The name of the archive, which will be the subdirectory it unpacks
to. Default: C<judoon>.

=head3 type_registry

An instance of L<Judoon::TypeRegistry> for looking up type properties.

=cut

has standalone_index => (is => 'lazy',);
sub _build_standalone_index { return 'index.html'; }
has standalone_db => (is => 'lazy',);
sub _build_standalone_db { return 'cgi-bin/database.tab'; }
has standalone_types => (is => 'lazy',);
sub _build_standalone_types { return 'cgi-bin/datatypes.tab'; }

has template_dir => (is => 'lazy',);
sub _build_template_dir { return path('root/src/standalone'); }
has skeleton_dir => (is => 'lazy',);
sub _build_skeleton_dir { return $_[0]->template_dir->child('skeleton'); }
has index_tmpl => (is => 'lazy',);
sub _build_index_tmpl { return $_[0]->template_dir->child('index.tt2'); }

has tt => (is => 'lazy',);
sub _build_tt { return Template->new; }

has archive_name => (is => 'lazy',);
sub _build_archive_name { return 'judoon'; }


has type_registry => (is => 'lazy',);
sub _build_type_registry { Judoon::TypeRegistry->new }

sub _build_archive {
    my ($self) = @_;
    my $archive = Archive::Builder->new;
    my $archive_section = $archive->new_section($self->archive_name);

    # add static files
    my $iter = $self->skeleton_dir->iterator({recurse => 1});
    while (my $child = $iter->()) {
        if (not $child->is_dir) {
            my $child_path = $child->relative($self->skeleton_dir);
            $archive_section->new_file(
                $child_path->stringify, 'file', $child->stringify
            ) or Judoon::Error::Devel::Foreign->throw({
                message => "error adding file to archive: ($child_path|$child)",
                module  => 'Archive::Builder',
                foreign_message => $archive->errstr,
            });
        }
    }

    # mark data.cgi as executable, so permissions work
    $archive_section->file('cgi-bin/data.cgi')->executable;

    # remove plugins.js; download uses minified version
    $archive_section->remove_file('js/plugins.js');

    # add index
    my $column_json = $self->encode_json([
        map {{
            title       => $_->title,
            template    => $_->template->to_jstmpl,
            sort_fields => join("|", $_->template->get_display_variables),
        }} $self->page->page_columns_ordered->all
    ]);
    $archive_section->new_file(
        'index.html', 'template', $self->tt, $self->index_tmpl->stringify,
        {page => $self->page, column_json => $column_json},
    ) or Judoon::Error::Devel::Foreign->throw({
        message         => "Can't fill in index Template via Archive",
        module          => 'Template or Archive::Builder',
        foreign_message => $archive->errstr,
    });

    # add database
    my $dataset = $self->page->dataset;
    my $raw_data = Judoon::Table->new({
        data_source => $dataset, header_type => 'short', format => 'tsv',
    })->render;
    $archive_section->new_file($self->standalone_db, 'string', $raw_data);

    # add datatypes
    $archive_section->new_file(
        $self->standalone_types, 'string',
        join("\t", map {$self->type_registry->simple_lookup($_->{data_type})->pg_type}
                 $dataset->ds_columns_ordered->hri->all)
    );

    Judoon::Error::Devel::Foreign->throw({
        message         => "Can't build Standalone archive",
        module          => 'Archive::Builder',
        foreign_message => $archive->errstr,
    }) if ($archive->errstr);

    return $archive;
}


=head1 METHODS

=head2 compress

Once the archive is built, compress it into either a zip file or a
gzipped tarball.  The archive is saved into a temporary file and the
path to the temporary file is returned.

=cut

sub compress {
    my ($self, $type) = @_;
    my $archive_compressed = $self->archive->archive($type || 'zip')
        or Judoon::Error::Devel::Foreign->throw({
            message         => "Can't compress archive as " . ($type || 'zip'),
            module          => 'Archive::Builder',
            foreign_message => $self->archive->errstr,
        });
    my ($fh, $filename) = tempfile(SUFFIX => ".$type", UNLINK => 1,);
    $archive_compressed->save( $filename )
        or Judoon::Error::Devel::Foreign->throw({
            message         => "Can't save compressed archive",
            module          => 'Archive::Builder',
            foreign_message => $self->archive->errstr,
        });
    return $filename;
}


1;
__END__

=head1 AUTHOR

Fitz ELLIOTT <felliott@fiskur.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by the Rector and Visitors of the
University of Virginia.

This is free software, licensed under:

 The Artistic License 2.0 (GPL Compatible)

=cut
