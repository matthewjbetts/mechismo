#!/usr/bin/perl -w

use strict;
use warnings;
use Getopt::Long;
use Cwd qw(abs_path getcwd);
use File::Path qw(make_path);
use Fist::Schema;
use Dir::Self;
use Config::General;
use Carp;
use Fist::Utils::Search;

# options
my $help;
my $types = [];
my $n_jobs_default = -1;
my $n_jobs = $n_jobs_default;
my $wait_default = 10;
my $wait = $wait_default;
my $fn_pid;

# other variables
my $conf;
my $config;
my $schema;
my $search;
my $job_rs;
my $job;
my $id_search;
my $n_jobs_done;
my $dn_search;
my $fn_search;
my $params;
my $json;
my $fn_json;
my $fh_json;
my $path;
my $fh_pid;

# parse command line
GetOptions(
	   'help'     => \$help,
           'type=s'   => $types,
           'n_jobs=i' => \$n_jobs,
           'wait=i'   => \$wait,
           'pid=s'    => \$fn_pid,
	  );

defined($help) and usage();

sub usage {
    my($msg) = @_;

    my $prog;
    my $usage;

    ($prog = __FILE__) =~ s/.*\///;

    defined($msg) and warn("\nUsage problem: $msg\n");

    $usage = <<END;

Usage: $prog [options]

option      parameter  description                                                default
----------  ---------  ---------------------------------------------------------  -------
--help      [none]     print this usage info and exit
--type [1]  string     type of jobs to run ('short' or 'long')                    [all]
--n_jobs    integer    number of jobs to run (-1 = infinite loop)                 $n_jobs_default
--wait      integer    number of seconds to sleep before retrieving the next job  $wait_default
--pid       string     write process id to named file                             [none]

Where:

1 - these options can be used more than once

END

    die $usage;
}

if(defined($fn_pid)) {
    open($fh_pid, ">$fn_pid") or die("Error: cannot open '$fn_pid' file for writing.");
    print $fh_pid $$;
    close($fh_pid);
}

$conf = Config::General->new(__DIR__ . "/../fist.conf");
%{$config} = $conf->getall;
$dn_search = defined($config->{dn_search}) ? $config->{dn_search} : '/tmp/';
$schema = Fist::Schema->connect($config->{"Model::FistDB"}->{connect_info}->{dsn}, $config->{"Model::FistDB"}->{connect_info}->{user}, $config->{"Model::FistDB"}->{connect_info}->{password});
$search = Fist::Utils::Search->new(config => $config);
$job_rs = $schema->resultset('Job');
$n_jobs_done = 0;
while(($n_jobs_done <= $n_jobs) or ($n_jobs < 0)) {
    if(defined($job = $job_rs->next_queued($config->{queue_name}, @{$types}))) {
        $id_search = $job->id_search;

        # read the query parameters from the search file as a json string
        $fn_search = join '', (($dn_search =~ /\/\Z/) ? $dn_search : "${dn_search}/"), $id_search, '/', $id_search, '.job';
        (-e $fn_search) or ($fn_search .= '.gz');
        if(defined($params = Fist::Utils::Search::read_json_file($fn_search))) {
            $params->{dn_search} = $dn_search; # not written to the job file so that it can more easily be changed
            $path = "/search/id/$id_search";

            $json = $search->search_by_text($schema, $path, $params);
            if(defined($json)) {
                # write json to file
                $fn_json = join '', (($dn_search =~ /\/\Z/) ? $dn_search : "${dn_search}/"), $id_search, '/', $id_search, '.json.gz';
                if(Fist::Utils::Search::write_json_file($fn_json, $json) == 1) {
                    # mark the job as finished
                    $job->update({status => 'finished', finished => time});
                }
                else {
                    $job->update({status => 'error', message => "Cannot open '$fn_json' file for writing"});
                }
            }
            else {
                $job->update({status => 'error', message => "search_by_text failed"});
            }
        }
        else {
            $job->update({status => 'error', message => "cannot read search parameters from '$fn_search' file"});

            # FIXME - job files cannot always be read for some reason, so re-queue them and try again later
            #$job->update({status => 'queued', message => "cannot read search parameters from '$fn_search' file"});
        }
    }

    ++$n_jobs_done;
    (($n_jobs_done >= $n_jobs) and ($n_jobs > 0)) and last;
    sleep($wait);
}

