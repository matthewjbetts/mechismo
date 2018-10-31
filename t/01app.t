#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use HTTP::Headers;
use HTTP::Request::Common;

use Catalyst::Test 'Fist';

my $request;
my $response;

# GET request
$request = GET('http://localhost');
$response = request($request);
ok($response = request($request), 'Basic request to start page');
ok($response->is_success, 'Start page successful 2xx');
is($response->content_type, 'text/html', 'HTML content type');

# test contact hit
$response = undef;
$request = POST(
                'http://localhost/contact_hit',
                'Content-Type' => 'form-data',
                'Content'      => [
                                   id => 1,
                                  ],
               );
ok($response = request($request), 'Request for contact hit');
ok($response->is_success, 'contact hit request successful 2xx');
is($response->content_type, 'text/html', 'HTML content type');
#like($response->content, qr/ContactHit/, "contains 'ContactHit'");

# test contact hit service
# FIXME - add json views back
#$response = undef;
#$request = POST(
#                'http://localhost/contact_hit_json',
#                'Content-Type' => 'form-data',
#                'Content'      => [
#                                   id => 1,
#                                  ],
#               );
#
#ok($response = request($request), 'Request for contact hit JSON');
#ok($response->is_success, 'contact hit request successful 2xx');
#is($response->content_type, 'application/json', 'JSON content type');
#like($response->content, qr/ContactHit/, "contains 'ContactHit'");

done_testing();
