#!/usr/bin/perl -w

use strict;
use warnings;

use Getopt::Long;
use Config::General;
use Cwd qw(abs_path getcwd);
use File::Path qw(make_path);
use Dir::Self;
use Fist::Schema;
use Fist::Utils::Search;

# options
my $help;
my $dn_out_default = './';
my $dn_out = $dn_out_default;
my $fn_search;
my $id_search;
my $all_ppis;
my $all_structs;
my $taxon;
my $stringency_default = 'low';
my $stringency = $stringency_default;
my $memory;
my $no_query_cache;
my $isoforms;
my $extSites = [];

# other variables
my $conf;
my $config;
my $schema;
my $params;
my $search;
my $json;
my $fn_json;

# parse command line
GetOptions(
	   'help'           => \$help,
           'outdir=s'       => \$dn_out,
           'job=s'          => \$fn_search,
           'id=s'           => \$id_search,
           'all_ppis'       => \$all_ppis,
           'all_structs'    => \$all_structs,
           'taxon=i'        => \$taxon,
           'stringency=s'   => \$stringency,
           'isoforms'       => \$isoforms,
           'ext_sites=s'    => $extSites,
           'memory'         => \$memory,
           'no_query_cache' => \$no_query_cache,
	  );

defined($help) and usage();
defined($fn_search) or defined($id_search) or usage('one of --job or --id required');
(@ARGV == 0) or usage();

sub usage {
    my($msg) = @_;

    my $prog;
    my $usage;

    ($prog = __FILE__) =~ s/.*\///;

    defined($msg) and warn("\nUsage problem: $msg\n");

    $usage = <<END;

Usage: $prog [options] < search_text

(search_text read from --job file if given, not STDIN)

option            parameter  description                                                    default
----------------  ---------  -------------------------------------------------------------  -------
--help            [none]     print this usage info and exit
--outdir          string     directory for output files                                     $dn_out_default
--job             string     job file (contents override other
                             settings except for outdir)
--id              string     identifier for the search (output                              [none]
                             files written with this prefix)
--all_ppis        [none]     get all prot-prot int matches, not
                             just the best per interactor
--all_structs     [none]     get all structure matches, not just
                             the best for each residue
--taxon           integer    NCBI taxon identifier                                          [any]
--stringency      string     high | medium | low | all                                      $stringency_default
--isoforms        [none]     include non-canonical isoforms as possible interactors         [do not include]
--ext_sites       string     include sites from given external source, eg 'uniprot|MUTAGEN'
--memory          [none]     STDERR report of memory used
--no_query_cache  [none]     disable query cache (for profiling)

END

    die $usage;
}

$conf = Config::General->new(__DIR__ . "/../fist.conf");
%{$config} = $conf->getall;
$schema = Fist::Schema->connect($config->{"Model::FistDB"}->{connect_info}->{dsn}, $config->{"Model::FistDB"}->{connect_info}->{user}, $config->{"Model::FistDB"}->{connect_info}->{password});
$no_query_cache and $schema->disable_query_cache(); # when optimising, disable query cache for more comparable run times
$search = Fist::Utils::Search->new(config => $config);

if(defined($fn_search)) {
    $params = Fist::Utils::Search::read_json_file($fn_search);
    $params->{dn_search} = $dn_out;
    $id_search = $params->{id_search};
}
else {
    $params = {
               dn_search  => $dn_out,
               id_search  => $id_search,
               stringency => $stringency,
               taxon      => $taxon,
               search     => join('', <STDIN>),
               isoforms   => defined($isoforms) ? 'yes' : 'no',
               extSites   => $extSites,
              };
}

# results are put in a sub dir of dn_out
(-e "${dn_out}/$id_search") or make_path("${dn_out}/$id_search");
$dn_out = abs_path($dn_out) . '/';

$json = $search->search_by_text($schema, 'command-line', $params, $memory, $all_ppis, $all_structs);

$fn_json = join '', (($dn_out =~ /\/\Z/) ? $dn_out : "${dn_out}/"), $id_search, '/', $id_search, '.json.gz';
Fist::Utils::Search::write_json_file($fn_json, $json) or warn("Error: cannot open '$fn_json' file for writing.");

if($memory) {
    require Devel::Size;
    $Devel::Size::warn = 0;
    $Devel::Size::warn = 0; # 2nd time just to suppress 'used only once' warning

    my $g2b = 1024 ** 3;
    my $cache = Fist::Interface::Alignment::cache;
    foreach my $obj ($cache, $json, $search, $schema) {
        warn sprintf("%.02fG\t%s\n", Devel::Size::total_size($obj) / $g2b, $obj);
    }
}
