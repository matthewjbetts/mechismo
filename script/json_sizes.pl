#!/usr/bin/perl -w

use strict;

use JSON::Any;
use Devel::Size;
$Devel::Size::warn = 0;
$Devel::Size::warn = 0; # 2nd time just to suppress 'used only once' warning

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
get_sizes(['json'], $json, 0, -1);

sub get_sizes {
    my($keys, $value, $level, $maxdepth) = @_;

    my $ref;
    my $g2b = 1024 ** 3;
    my $key2;
    my $value2;

    $ref = ref $value;

    if(($ref eq 'ARRAY')) {
        printf "%.06fG\t%s (%s)\n", Devel::Size::total_size($value) / $g2b, join('->', @{$keys}), $ref;
        for($key2 = 0; $key2 < @{$value}; $key2++) {
            push @{$keys}, $key2;
            $value2 = $value->[$key2];
            get_sizes($keys, $value2, $level + 1, $maxdepth);
            pop @{$keys};
        }
    }
    elsif(($ref eq 'HASH') and (($level < $maxdepth) or ($maxdepth < 0))) {
        printf "%.06fG\t%s (%s)\n", Devel::Size::total_size($value) / $g2b, join('->', @{$keys}), $ref;
        while(($key2, $value2) = each %{$value}) {
            push @{$keys}, $key2;
            get_sizes($keys, $value2, $level + 1, $maxdepth);
            pop @{$keys};
        }
    }
}
