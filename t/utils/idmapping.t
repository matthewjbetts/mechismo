use strict;
use warnings;
use Test::More;
use Config::General;
use Fist::Schema;
use Fist::Utils::IdMapping;

my $conf;
my %config;
my $schema;
my $id_mapping;
my $my_mapping;
my $space;
my @types;
my $type;
my $id_old;
my $id_new;
my $n;
my $n_spaces;
my $unique;

$conf = Config::General->new('fist.conf');
%config = $conf->getall;
$schema = Fist::Schema->connect($config{"Model::FistDB"}->{connect_info}->{dsn}, $config{"Model::FistDB"}->{connect_info}->{user}, $config{"Model::FistDB"}->{connect_info}->{password});

# single-space mapping
eval { $id_mapping = Fist::Utils::IdMapping->new(schema => $schema); };
ok(!$@, 'constructed IdMapping object');

$unique = {};
$my_mapping = {};
$n = 10;
$space = 1;
$type = 'Test';
for($id_old = 1; $id_old <= $n; $id_old++) {
    $id_new = $id_mapping->id_new($space, $type, $id_old);
    store_mapping($my_mapping, $unique, $space, $type, $id_old, $id_new);
}

ok(check_mapping($my_mapping, $id_mapping) == 0, 'single-space mapping stored correctly');
ok(check_unique($unique) == 0, 'single-space mapping new ids are unique');


# multi-space mapping
eval { $id_mapping = Fist::Utils::IdMapping->new(schema => $schema); };
ok(!$@, 'constructed IdMapping object');

$unique = {};
$my_mapping = {};
$n = 10;
$n_spaces = 5;
@types = ('TestA', 'TestB', 'TestC');
for($space = 1; $space <= $n_spaces; $space++) {
    foreach $type (@types) {
        for($id_old = 1; $id_old <= $n; $id_old++) {
            $id_new = $id_mapping->id_new($space, $type, $id_old);
            store_mapping($my_mapping, $unique, $space, $type, $id_old, $id_new);
            #print join("\t", $space, $type, $id_old, $id_new), "\n";
        }
    }
}

# add some old identifiers to a space already seen
if(1) {
    $space = 1;
    $type = 'TestA';
    for($id_old = $n + 1; $id_old <= $n + 10; $id_old++) {
        $id_new = $id_mapping->id_new($space, $type, $id_old);
        store_mapping($my_mapping, $unique, $space, $type, $id_old, $id_new);
        #print join("\t", $space, $type, $id_old, $id_new), "\n";
    }
}

ok(check_mapping($my_mapping, $id_mapping) == 0, 'multi-space mapping stored correctly');
ok(check_unique($unique) == 0, 'multi-space mapping new ids are unique');

done_testing();

sub store_mapping {
    my($my_mapping, $unique, $space, $type, $id_old, $id_new) = @_;

    $my_mapping->{$space}->{$type}->{$id_old} = $id_new;
    $unique->{$type}->{$id_new}->{"$space:$id_old"}++;
}

sub check_unique {
    my($unique) = @_;

    my $n_not_unique;
    my $type;
    my $id_new;

    $n_not_unique = 0;
    foreach $type (keys %{$unique}) {
        foreach $id_new (keys %{$unique->{$type}}) {
            #(scalar(keys(%{$unique->{$type}->{$id_new}})) > 1) and ++$n_not_unique;
            if(scalar(keys(%{$unique->{$type}->{$id_new}})) > 1) {
                print join("\t", $type, $id_new, sort(keys(%{$unique->{$type}->{$id_new}}))), "\n";
                ++$n_not_unique;
            }
        }
    }

    return $n_not_unique;
}

sub check_mapping {
    my($my_mapping, $id_mapping) = @_;

    my $n_wrong;
    my $space;
    my $type;
    my $id_old;
    my $id_new;

    $n_wrong = 0;
    foreach $space (keys %{$my_mapping}) {
        foreach $type (keys %{$my_mapping->{$space}}) {
            foreach $id_old (keys %{$my_mapping->{$space}->{$type}}) {
                $id_new = $id_mapping->id_new($space, $type, $id_old);
                ($id_new == $my_mapping->{$space}->{$type}->{$id_old}) or ++$n_wrong;
            }
        }
    }

    return $n_wrong;
}
