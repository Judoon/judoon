

test:
	prove -Pretty -vl t

author_tests:
	prove -Pretty -vlr t

installdeps:
	cpanm --installdeps .

cover:
	PERL5OPT=-MDevel::Cover=+-silent,1 prove -Pretty -vl

report:
	cover -report html_basic -ignore_re 'prove'

forkprove:
	forkprove -MMoose -MCatalyst -MDBIx::Class -j3 -lr t

reindex:
	perl share/scripts/search/reindex.pl
