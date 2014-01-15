# Installing and running Judoon

Judoon can be run as a development server or as a deployment server.
This document describes how to set up a development server.  For
deployment instructions, see share/docs/deployment.pod.

# Prereqs

Make sure the following packages are installed (these are the CentOS
6.3 names):

* gcc
* git
* postgresql
* postgresql-devel
* expat-devel
* openssl-devel
* elasticsearch
* memcached

Make sure the following services are running:

* postgresql
* elasticsearch
* memcached


# Quickstart

    $ git clone $judoon_repo.git judoon
    $ cd judoon
    $ cpanm --installdeps .
    $ cp share/doc/sample_config/*.conf .
    $ emacs *.conf # make local changes
    $ ./share/scripts/schema/migrate.pl install
    $ plackup -Ilib judoon_web.psgi
