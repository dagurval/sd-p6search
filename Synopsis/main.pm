package Perlcrawl;
use Carp;
use Data::Dumper;
use strict;
use warnings;
use LWP::Simple qw(get);
use Date::Parse qw(str2time);

use Crawler;
our @ISA = qw(Crawler);

##
# Main loop for a crawl update.
# This is where a resource is crawled, and documents added.
sub crawl_update {
    my (undef, $self, $opt) = @_;

    my $SYN_URL = "http://perlcabal.org/syn";

    my $index = get($SYN_URL) 
        or die "unable to fetch index";

    my @chapters;
    for my $line (split "\n", $index) {
         # match: 
         #       <td><a href="S01.html"><strong>Synopsis</strong></a></td>
         #        <td><a href="S32/IO.html"><strong>Synopsis</strong></a></td>
         next unless $line =~ /(S[0-9]+(?:\/\w+)?.html).*Synopsis/;
         push @chapters, $SYN_URL . "/" . $1;
    }

    print STDERR "NUM CHAPTERS", scalar @chapters, "\n";

    for my $c (@chapters) {
        my %attr,
        my $content = get($c);
        if (!$content) {
            warn "Unable to fetch '$c'";
            next;
        }
        
        # <pre> Last Modified: 4 Jul 2013
        $content =~ /Last Modified: (.*?20\d\d)/;
        $attr{"last modified"} = $1 if $1;
        
        $content =~ /Version: (\d+)/;
        $attr{version} = $1 if $1;

        $content =~ /Created: (.*?\d{4})/;
        $attr{created} = $1 if $1;

        $content =~ m{TITLE</a></h1>\s*<p>(.*?)</p>};
        my $title = $1 || "Synopsis";

        my $time = str2time($attr{"last modified"}) || time;
        my $size = length($content);

        next if $self->document_exists($c, $time, $size);

        $self->add_document((
            type => 'html', content => $content, title => $title, url => $c,
            acl_allow => "Everyone", last_modified => $time, attributes => \%attr));
    }
};

sub path_access {
    1;
}

1;
