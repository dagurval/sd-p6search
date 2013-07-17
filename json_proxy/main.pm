package Perlcrawl;
use Carp;
use Data::Dumper;
use JSON::XS;
use LWP::Simple qw(get);
use strict;
use warnings;

use Crawler;
our @ISA = qw(Crawler);

##
# Main loop for a crawl update.
# This is where a resource is crawled, and documents added.
sub crawl_update {
    my (undef, $self, $opt) = @_;

    print("JSON crawler options received: ", Dumper($opt));
	my $url = $opt->{url}
		or die "Setting 'url' missing";
	
	get($url . "/startcrawl")
		or die "Unable to fetch $url/startcrawl";

	my $i = 0;
	while (my $doc_raw = get("$url/nextdoc")) {
		$i++;
		my $doc = JSON::XS->new->decode($doc_raw)
			or warn "unable to json decode doc: $doc_raw";
	
		next unless $doc;
	
		next if $self->document_exists(
			$doc->{url}, $doc->{last_modified}, $doc->{size});
		
		$self->add_document(%{$doc});
	}
}

sub path_access {
    return 1;
}

1;
#vim: set tabstop=4
