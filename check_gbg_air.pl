#!/usr/bin/env perl 
#===============================================================================
#       AUTHOR: Jonatan Sundeen
#       Requires: Curl
#===============================================================================

use strict;
use warnings;
use utf8;
use Getopt::Std;
use JSON;
use LWP::Simple;
use LWP::UserAgent;
use HTTP::Request;
use Data::Dumper;

my $usage ='
Usage:
<path> <input-file-name>

    -a  Check via http
        -k  key (required by http)
        -u  url (required by http)
    -d  debug enabled
    -f  Check using stdin
    -h  help
    
Example:
# ./check_gbg_air.pl -a -k "my secret key"

Example from file:
# ./check_gbg_air.pl -f < example_data_1.json

';

my $host = "http://data.goteborg.se/AirQualityService/v1.0/LatestMeasurement/";
my %AirQuality;
my %Weather;
my $line_counter;
my $response;
my $key = "";
my $url = "";


our ($opt_a,$opt_h,$opt_d,$opt_f,$opt_u,$opt_k);
getopts('abdhfu:k:s:');

if ( $opt_h ) {
    usage();
}

if($opt_d) {
    print "Debug on\n";
}


if($opt_a) {
    $key = $opt_k if $opt_k;
    $url = "$host/$key?format=json";
    $url = $opt_u if $opt_u;
    print "URL: $url\n" if $opt_d;
    $response = curl_url($url);
} elsif ($opt_f) {
    while (my $line=<STDIN>) {
        $response .= $line;
    }
} else {
    usage();
}

process_json($response);
check_all();

sub check_all {
    my ($accepted, $warning) = @_;
    my $all_ok = 1;
    my $result = "";
    my $perfdata = "";
    
    my $count_bad = 0;
    my $count_ok = 0;
    my $count_tot = 0;

    foreach my $key (keys %AirQuality) {
        $count_tot++;

        $perfdata .= " '$key'=$AirQuality{$key};;;;";
        
        $result .= "$key: $AirQuality{$key}, ";
    }
    
    foreach my $key (keys %Weather) {
        $count_tot++;

        $perfdata .= " '$key'=$Weather{$key};;;;";
        
        $result .= "$key: $Weather{$key}, ";
    }

    $result =~ s/, $//mg;
    print "$result | $perfdata \n";
    if ($all_ok) {
        exit 0;
    } else {
        exit 1;
    }
}

sub process_json {
    my $decoded_json = JSON->new->decode( $_[0] );

    if ($opt_d) {
        print Dumper $decoded_json;
        
        print "key: $_\n" for keys %{$decoded_json};
        print "\n";
        print "\n";
    }
    
    my $value = "nostatus";

    my $key1 = "AirQuality";
    my $key2 = "Weather";
    
    foreach my $keyA ( keys %{$decoded_json}) {
        print "$keyA ref($decoded_json->{$keyA}) \n" if $opt_d;
        if (ref($decoded_json->{$keyA}) eq 'HASH' ) {
        if (exists $decoded_json->{$keyA} ) {
        if (defined $decoded_json->{$keyA} ) {
        foreach my $keyB ( keys %{$decoded_json->{$keyA}}) {
            print "   $keyB ref($decoded_json->{$keyA})\n" if $opt_d;
            if (ref($decoded_json->{$keyA}->{$keyB}) eq 'HASH' ) {
            if (exists $decoded_json->{$keyA}->{$keyB}->{"Value"} ) {
                if ("$keyA" eq $key1) {
                $AirQuality{$keyB}=$decoded_json->{$keyA}->{$keyB}->{"Value"};
                print "      $AirQuality{$keyB}\n" if $opt_d;;
                } elsif ($keyA eq $key2) {
                $Weather{$keyB}=$decoded_json->{$keyA}->{$keyB}->{"Value"};
                print "      $Weather{$keyB}\n"  if $opt_d;;
                }
            }
            }
        }
        }
        }
        }
        print "\n"  if $opt_d;;
    }
}

sub print_all {    
    foreach my $key (keys %AirQuality) {
        printf("%s: \"%s\" \n", $key, $AirQuality{$key});
    }
    foreach my $key (keys %Weather) {
        printf("%s: \"%s\" \n", $key, $Weather{$key});
    }
    my $AirQuality_size = keys %AirQuality;
    my $Weather_size = keys %Weather;
    print "Count AirQuality_size: $AirQuality_size; Count Weather_size: $Weather_size\n";
}

sub get_url {
    my ($url, $data) = @_;
    my $ua = LWP::UserAgent->new(ssl_opts => { verify_hostname => 1 });
    my $header = ['Content-Type' => 'application/x-www-form-urlencoded'];
    my $request = HTTP::Request->new('POST', $url, $header, $data);
    my $response = $ua->request($request);

    if ($opt_d) {
    print "\n";
    print "Response: ".$response->decoded_content . "\n";
    if ($response->is_success){
        print "URL success: $url\nHeaders:\n";
        print $response->headers_as_string;
    }elsif ($response->is_error){
        print "Error:$url\n";
        print $response->error_as_HTML;
    }
    }
    return $response->decoded_content;
}

sub curl_url {
    my ($url, $data) = @_;
    my $result = undef;
    if ($data) {
        $result = `curl -s $url --data '$data'`;
    } else {
        $result = `curl -s $url`;
    }
    return "$result";
}

sub usage {
    print $usage;
}
