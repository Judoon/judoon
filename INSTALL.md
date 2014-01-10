# Installing and running Judoon

Judoon can be run as a development server or as a deployment server.
This document describes how to set up a development server.  For
deployment instructions, see share/docs/deployment.pod.

# Quickstart

    $ git clone $judoon_repo.git judoon
    $ cd judoon
    $ yum install postgresql postgresql-devel elasticsearch
    $ cpanm --installdeps .
    $ cp share/doc/sample_config/*.conf .
    $ emacs *.conf # make local changes
    $ ./share/scripts/schema/migrate.pl install
    $ plackup -Ilib judoon_web.psgi
