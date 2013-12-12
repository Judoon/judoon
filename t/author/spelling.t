#!/usr/bin/env perl

use strict;
use warnings;

use Test::Spelling;

add_stopwords(<DATA>);
set_spell_cmd('aspell list -l en');
all_pod_files_spelling_ok(qw(lib/Judoon lib/DBIx lib/Catalyst));

__DATA__
Judoon
Dataset
dataset
datasets
dataset's
DatasetColumn
DatasetColumns
PageColumn
PageColumns
SQLite
PostgreSQL
username
arrayref
arrayrefs
hashref
hashrefs
CSV
csv
SQL
sql
UUID
UUIDs
JSON
json
GETs
POSTs
PUTs
DELETEs
chainpoint
timestamp
subclasses
prefetch
Prefetch
prefetching
html
login
logout
Entrez
lookup
lookups
subkey
subkeys
url
urls
filename
metadata
seekable
xls
XLS
xlsx
XLSX
resultset
resultsets
namespace
namespaces
API
api
jQuery
RESTful
RESTish
Fitz
Elliott
javascript
js
signup
downloadable
subdirectory
webpage
Adaptor
cellmigration
AngularJS
utf
ElasticSearch
InflateColumn
Uniprot
DBIC
serializable
sitelinker
updatable
plaintext
shortnames
