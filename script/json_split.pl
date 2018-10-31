#!/usr/bin/perl -w

use strict;

use JSON;

my $prefix;
my $json_str;
my $json_encoder;
my $json;
my $key;
my $value;
my $fn;

defined($prefix = shift @ARGV) or usage();

sub usage {
    my $prog;

    ($prog = __FILE__) =~ s/.*\///;

    die "Usage: $prog prefix < json\n";
}

$json_str = [];
while(<STDIN>) {
    push @{$json_str}, $_;
}
$json_str = join '', @{$json_str};
$json_encoder = JSON->new->allow_nonref;
$json = $json_encoder->decode($json_str);
undef $json_str;

while(($key, $value) = each %{$json}) {
    if(defined($value)) {
        $fn = "${prefix}${key}.json";
        (-e $fn) and die "Error: '$fn' file already exists.";
        open(OUT, ">$fn") or die "Error: cannot open '$fn' file for reading.";
        print OUT $json_encoder->encode($value);
        close(OUT);
    }
}

