# Judoon

Judoon is a web application that converts tabular data in an Excel
spreadsheet into a searchable and sortable table presented on the
World Wide Web. After upload to the Judoon website, spreadsheet data
is immediately displayed; editing commands can be used to reformat the
data columns and add images or links to other web resources, including
NCBI databases and Google.

New data can be pulled in from other spreadsheets or external
databases and presented together.  The finished presentation can then
be downloaded and hosted on the researcher's own website.

* Web site: http://www.judoon.org/
* Tutorial: nope. not yet.
* Github: https://github.com/Judoon/judoon


# Judoon layout structure

## cpanfile

Declares Judoon's perl dependencies

## lib/

All of the Judoon perl modules live here.

## root/

Where templates and web assets (css, js, images, etc) live.

## share/

Everything that doesn't belong somewhere else goes here.  Scripts,
fixtures, docs, deploy files, etc.

## t/

Tests and test fixtures for our Judoon code.
