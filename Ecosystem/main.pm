package Perlcrawl;
use Carp;
use Data::Dumper;
use strict;
use warnings;
use JSON::XS;
use LWP::Simple qw(get);
use Date::Parse;
use Text::Markdown;
use Pod::Simple::HTML;


use Crawler;
our @ISA = qw(Crawler);

## SD version of LWP::Simple does not
## have SSL support. Temp work around using curl
sub https_get {
   open my $ch, "-|", "curl", "-s", shift
      or return;
   return join "\n", <$ch>;
}

sub content_uri {
    my ($orig_uri, $readme_uri) = @_;
    return $orig_uri unless $readme_uri;
    $readme_uri =~ s|/blob/|/|;
    $readme_uri =~ s/github/raw.github/;
    
    return $readme_uri;
}

sub download_content {
    my ($orig, $readme) = @_;
    my $uri = content_uri($orig, $readme);
    my $content = https_get($uri);
    if (!$content) {
        warn "Got no content for $uri";
        return;
    }
    if ($uri =~ /markdown/i || $uri =~ /md$/i) {
          warn "Generating HTML for Markdown $uri\n";
          my $m = Text::Markdown->new;
          $content = $m->markdown($content);
    }
    if ($uri =~ /pod$/i) {
        warn "Generating HTML for POD $uri\n";
        my $p = Pod::Simple::HTML->new;
        $p->output_string(\my $pod_html);
        $p->parse_string_document($content);
        $content = $pod_html if $pod_html;
    }
    return https_get($orig) if !$content;
    return $content;
 
}

# Main loop for a crawl update.
# This is where a resource is crawled, and documents added.
sub crawl_update {
    my (undef, $self, $opt) = @_;

my $modules = "http://modules.perl6.org/proto.json";

my $json = get($modules) or die "unable to fetch $modules";
my $ecosystem_ref = JSON::XS->new->decode(get($modules))
        or die "unable to decode ecosystem";

while (my ($name, $a) = each %{$ecosystem_ref}) {
        my $title = $name;
        $title .= " - $a->{description}" if $a->{description};
        my $time = str2time($a->{last_updated}) || time;

        my $content = download_content($a->{url}, $a->{badge_has_readme});       
        #die $content;
        eval {
        $self->add_document((
                type => "html",
                content => $content,
                title => $title,
                url => $a->{url},
                acl_allow => "Everyone",
                last_modified => $time,
                attributes => {
                        "has tests" => $a->{badge_has_tests} ? "Yes" : "No",
                        "is fresh" => $a->{badge_is_fresh} ? "Yes" : "No",
                        "panda compatible" => $a->{badge_panda} ? "Yes" : "No",
                        "author" => $a->{auth},
                        "located at" => $a->{home}
                }
        ));
        };
        warn $@ if $@;
}


};

sub path_access { 1; }

1;
