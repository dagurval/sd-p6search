use v6;
use LWP::Simple;
use JSON::Tiny;

module P6Search::Crawl::Synopsis;

my @to-log;

class Synopsis {
	has $.SYN_URL = "http://perlcabal.org/syn/";

	method fetch-list() {
		my $index-html = LWP::Simple.get($.SYN_URL)
			or die "unable to fetch $.SYN_URL";

		my @chapters;
	    for $index-html.lines() -> $line {
			# match: <td><a href="S01.html"><strong>Synopsis</strong></a></td>
			next unless $line ~~ /(S<[0..9]>.*?html).*Synopsis/; 
			@chapters.push($.SYN_URL ~ $/[0]);
		}

		@chapters;
	}

	method crawl-all() {
		my $lwp = LWP::Simple.new;
		gather for self.fetch-list() -> $uri {
            push @to-log, "Fetching $uri";
            say "Fetching $uri";
			take {
				uri => $uri,
				content => $lwp.get($uri)
			}
		}
	}
}

use Bailador;

my @all-docs;

get '/' => sub {
    "Crawler is running!"
}

get '/startcrawl' => sub {
    my $syn = Synopsis.new;
    @all-docs := $syn.crawl-all();
    print; #nullop to lazy get crawl-all
}

get '/nextdoc' => sub {
    content_type "application/javascript";
    if not @all-docs {
        status 404;
        return "no document in queue";
    }

    my $doc = @all-docs.shift;
    $doc{'content'} ~~ /'TITLE</a></h1>' \s* '<p>' (.*?) '</p>'/;
    my $title = $/[0].Str || "Synopsis";

    my %d = {
        'content' => $doc{'content'},
        'title' => $title,
        'url' => $doc{'uri'},
        'type' => 'html',
        'acl_allow' => "Everyone",
        'last_modified' => time # XXX
    }

    return to-json(%d);
}

get '/log' => sub {
    my @cpy = @to-log;
    @to-log = ();
    return @cpy;

}

baile;
