#!/usr/bin/perl -w

use strict;

use JSON::Any;
use JSON::XS;

my $str;
my $encoder;
my $json;

$str = [];
while(<STDIN>) {
    push @{$str}, $_;
}
$str = join '', @{$str};
$encoder = JSON::Any->new();
$json = $encoder->jsonToObj($str);
print JSON::XS->new->pretty(1)->encode($json);
