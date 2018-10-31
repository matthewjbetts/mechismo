package Fist::Controller::Root;
use Moose;
use Fist::Utils::Search;
use File::Temp;
use JSON::Any;
use Dir::Self;
use Fist::Utils::SubstitutionMatrix;
use Net::IPAddress;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller' }

#
# Sets the actions in this controller to be registered with no prefix
# so they function identically to actions created in MyApp.pm
#
__PACKAGE__->config(namespace => '');

=head1 PACKAGE VARIABLES

=cut

my $colours = {A2 => '00FFFF', B2 => 'FF00FF'};

=head1 NAME

Fist::Controller::Root - Root Controller for Fist

=head1 DESCRIPTION

[enter your description here]

=head1 METHODS

=head2 index

The root page (/)

=cut

sub index :Path :Args(0) {
    my($self, $c) = @_;

    $c->stash(template => 'search.tt');
}

sub base :Chained('/') :PathPart('') :CaptureArgs(0) {
    my($self, $c) = @_;

    $c->stash(collection => $c->model('FistDB'));
    $c->stash(search => Fist::Utils::Search->new(config => $c->config));
}

=head2 jsmol

=cut

sub jsmol :Chained('base') :PathPart('jsmol') :Args(0) {
    my($self, $c) = @_;

    $c->stash(no_wrapper => 1);
    $c->stash(template => 'jsmol.tt');
}

=head2 about

=cut

sub about :Chained('base') :PathPart('about') :Args(0) {
    my($self, $c) = @_;

    $c->stash(template => 'about.tt');
}

=head2 examples

=cut

sub examples :Chained('base') :PathPart('examples') :Args(0) {
    my($self, $c) = @_;

    $c->stash(template => 'examples.tt');
}

=head2 faq

=cut

sub faq :Chained('base') :PathPart('faq') :Args(0) {
    my($self, $c) = @_;

    $c->stash(template => 'faq.tt');
}

=head2 help

=cut

sub help :Chained('base') :PathPart('help') :Args(0) {
    my($self, $c) = @_;

    $c->stash(template => 'help.tt');
}

=head2 sankey

=cut

sub sankey :Chained('base') :PathPart('sankey') :Args(0) {
    my($self, $c) = @_;

    $c->stash(template => 'sankey.tt');
}

=head2 search

=cut

sub search :Chained('base') :PathPart('search') :CaptureArgs(0) {
    my($self, $c) = @_;

    $c->stash(template => 'search.tt');
}

sub search_empty :Chained('search') :PathPart('') :Args(0) {
    my($self, $c) = @_;
}

=head2 search_by_text

=cut

sub search_by_text :Chained('search') :PathPart('text') :Args(0) {
    my($self, $c) = @_;

    my $schema;
    my $dh_search;
    my $dn_search;
    my $id_search;
    my $fn_search;
    my $url;
    my $job;
    my $type;
    my $path;
    my $params;
    my $text;
    my $json;
    my $alias;
    my $pos;
    my $n_aliases;
    my $n_labels;
    my $upload;
    my $ipstr;
    my $ipint;
    my $hostname;

    $schema = $c->stash->{collection}->schema;

    $dn_search = defined($c->config->{dn_search}) ? $c->config->{dn_search} : '/tmp/';
    #$fh_search = File::Temp->new(DIR => $dn_search, SUFFIX => '.job.gz', UNLINK => 0);
    #$fn_search = $fh_search->filename;
    #($id_search = $fn_search) =~ s/\A\S+\/(\S+)\.job\S*\Z/$1/;

    $dh_search = File::Temp->newdir(DIR => $dn_search, CLEANUP => 0);
    $dn_search = $dh_search->dirname;
    chmod(0755, $dn_search); # don't know why ->newdir sets it to 0700
    ($id_search = $dn_search) =~ s/\A\S+\/(\S+)\Z/$1/;
    $fn_search = "$dn_search/${id_search}.job.gz";

    $params = $c->req->params;
    $params->{id_search} = $id_search;

    if(!defined($params->{search}) or ($params->{search} eq "")) {
        if(defined($params->{search_file}) and ($params->{search_file} ne "")) {
            defined($upload = $c->req->upload('search_file')) and ($params->{search} = $upload->slurp);
        }
    }

    # write the query parameters to the search file as a json string
    Fist::Utils::Search::write_json_file($fn_search, $params);

    if(defined($text = $params->{search})) {
        $json = {};

        # using the same parser as in the main search, so that any
        # changes to the format will only need changes to one parser

        # find out how many aliases and sites are in the
        # query, and decide queue type on that basis
        Fist::Utils::Search::parse_search_text($schema, $json, $text);
        $n_aliases = scalar keys %{$json->{temporary_search}->{aliases}};
        $n_labels = 0;
        foreach $alias (keys %{$json->{temporary_search}->{aliases}}) {
            foreach $pos (keys %{$json->{temporary_search}->{aliases}->{$alias}->{posns}}) {
                $n_labels += scalar @{$json->{temporary_search}->{aliases}->{$alias}->{posns}->{$pos}};
            }
        }

        $type = ($n_aliases >= 50) ? 'long' : 'short';
    }
    else {
        $c->stash(error => 'No search text was given. Please see the <a href="/help.tt#input">help pages</a> for information on the input format required.');
        $c->forward('error');
    }

    $ipstr = $c->req->address;
    $ipint = ip2num($ipstr);
    ($hostname = qx(host $ipstr)) =~ s/.*domain name pointer (\S+)\.\n.*/$1/;

    $job = $schema->resultset('Job')->new_result({
                                                  id_search   => $id_search,
                                                  search_name => $params->{search_name},
                                                  ipint       => $ipint,
                                                  hostname    => $hostname,
                                                  queue_name  => $c->config->{queue_name},
                                                  n_aliases   => $n_aliases,
                                                  n_labels    => $n_labels,
                                                  type        => $type,
                                                  status      => 'queued',
                                                  queued      => time,
                                                 });
    $job->insert;

    $path = "/search/id/$id_search";

    # forward to the search page with the new id, so that it can be bookmarked
    # FIXME - not sure if this is good Catalyst practice...
    #$url = $c->uri_for($c->action, {id => $id_search});
    $url = $c->uri_for($path);
    $c->response->redirect($url);
}

sub search_by_text_end :Chained('search_by_text'): PathPart('') :Args(0) {}

sub search_by_text_viewtype :Chained('search_by_text') :PathPart('') :Args(1) {
    my($self, $c, $view) = @_;

    $self->set_view($c, $view);
}

=head2 search_by_id

=cut

sub search_by_id :Chained('search') :PathPart('id') :CaptureArgs(1) {
    my($self, $c, $id_search) = @_;

    my $schema;
    my $search;
    my $json;
    my $job;

    $c->stash(template => 'search_results.tt');

    $schema = $c->stash->{collection}->schema;
    $search = $c->stash->{search};
    #$json = {id_search => $id_search};
    #$c->stash(json => $json);

    $job = $schema->resultset('Job')->find({id_search => $id_search});
    if(!defined($job)) {
        # the job may have been run outside the queue
        $c->stash(template => 'search_results.tt');
        if(defined($json = json_from_search_id($c, $id_search))) {
            $json->{server_url} = $c->request->base->as_string;
            $c->stash(json => $json);
        }
        else {
            $c->forward('error');
        }
    }
    elsif($job->status eq 'queued') {
        $json->{params}->{given} = json_from_search_id($c, $id_search, '.job');
        $c->stash(template => 'search_running.tt');
        $c->stash(job => $job); # FIXME - get the position in the queue
        $c->stash(refresh_rate => 10000);
    }
    elsif($job->status eq 'running') {
        $json->{params}->{given} = json_from_search_id($c, $id_search, '.job');
        $c->stash(template => 'search_running.tt');
        $c->stash(job => $job); # FIXME - get the position in the queue
        $c->stash(refresh_rate => 10000);
    }
    elsif($job->status eq 'finished') {
        $c->stash(template => 'search_results.tt');
        if(defined($json = json_from_search_id($c, $id_search))) {
            $json->{server_url} = $c->request->base->as_string;
            $c->stash(json => $json);
        }
        else {
            $c->forward('error');
        }
    }
    elsif($job->status eq 'error') {
        $c->stash(error => $job->message);
        $c->forward('error');
    }
    else {
        $c->stash(error => join('', "Unrecognised job status '", $job->status, "'"));
        $c->forward('error');
    }
}

sub search_by_id_end :Chained('search_by_id'): PathPart('') :Args(0) {}

sub search_by_id_view_type :Chained('search_by_id') :PathPart('') :CaptureArgs(1) {
    my($self, $c, $view_type) = @_;

    $self->set_view($c, $view_type);
}

sub search_by_id_view_type_end :Chained('search_by_id_view_type'): PathPart('') :Args(0) {}

sub search_by_id_data :Chained('search_by_id'): PathPart('data') : Args(1) {
    my($self, $c, $type) = @_;

    my $json;
    my $id_search;
    my $dn_search;
    my $fn;

    $json = $c->stash->{json};
    $dn_search = defined($c->config->{dn_search}) ? $c->config->{dn_search} : '/tmp/';
    $id_search = $json->{params}->{given}->{id_search};

    # FIXME - could add parameters for DataTables server-side processing?

    if(defined($json->{results}->{search}->{$type}) and ($json->{results}->{search}->{$type} =~ /FILE:(\S+)/)) {
        $fn = $1;
    }
    else {
        $c->stash(error => "No $type file found");
        $c->forward('error');
    }

    #$c->{stash}->{json} = {fn => $fn}; # for debugging
    $c->{stash}->{json} = $c->stash->{search}->process_table($type, $id_search, $dn_search, $fn);

    $self->set_view($c, 'json');
}

# can use search results as a cache for other pages, eg. sequence
# information, as long as they know the search id. These actions
# can be end points in themselves - don't need separate alternative
# view actions (eg. for JSON) as the data is the same as provided
# by the search, so should just use /search/id/*/json for that.

=head2 search_seq

=cut

sub search_seq :Chained('search_by_id') :PathPart('seq') :CaptureArgs(0) {
    my($self, $c) = @_;

    $c->stash(template => 'seq.tt');
}

sub search_seq_by_id :Chained('search_seq') :PathPart('') :CaptureArgs(1) {
    my($self, $c, $id_seq) = @_;

    my $schema;
    my $search;
    my $json;

    $schema = $c->stash->{collection}->schema;
    $search = $c->stash->{search};
    $json = $c->stash->{json};

    if(!defined($search->seq_by_id($schema, $c->req->path, $c->req->params, $id_seq, $json))) {
        # FIXME - return a more informative error
        $c->forward('default');
    }
}

sub search_seq_by_id_end :Chained('search_seq_by_id') :PathPart('') :Args(0) {}

sub search_seq_by_id_view_type :Chained('search_seq_by_id') :PathPart('') :Args(1) {
    my($self, $c, $view_type) = @_;

    $self->set_view($c, $view_type);
}

sub search_frag_hit :Chained('search_by_id') :PathPart('frag_hit') :Args(0) {
    my($self, $c) = @_;

    my $schema;
    my $search;
    my $json;

    $schema = $c->stash->{collection}->schema;
    $search = $c->stash->{search};
    $json = $c->stash->{json};

    if($search->frag_hit($schema, $c->req->path, $c->req->params, $json)) {
        $c->stash(template => 'frag_hit.tt', colours => $colours);
    }
    else {
        # FIXME - return a more informative error
        $c->forward('default');
    }
}

sub search_contact_hit :Chained('search_by_id') :PathPart('contact_hit') :Args(1) {
    my($self, $c, $id) = @_;

    my $schema;
    my $search;
    my $json;
    my $ids;

    $schema = $c->stash->{collection}->schema;
    $search = $c->stash->{search};
    $json = $c->stash->{json};

    $ids = [split /,/, $id];
    if(@{$ids} == 1) {
        if($search->contact_hit_by_id($schema, $c->req->path, $c->req->params, $id, $json)) {
            $c->stash(template => 'contact_hit.tt', colours => $colours);
        }
        else {
            # FIXME - return a more informative error
            $c->forward('default');
        }
    }
    else {
        if($search->contact_hits_by_ids($schema, $c->req->path, $c->req->params, $ids, $json)) {
            $c->stash(template => 'contact_hits.tt');
        }
        else {
            # FIXME - return a more informative error
            $c->forward('default');
        }
    }
}

=head2 seq

=cut

sub seq :Chained('base') :PathPart('seq') :CaptureArgs(0) {
    my($self, $c) = @_;

    $c->stash(template => 'seq.tt');
}

sub seq_by_id :Chained('seq') :PathPart('') :Args(1) {
    my($self, $c, $id_seq) = @_;

    my $schema;
    my $search;
    my $json;

    $schema = $c->stash->{collection}->schema;
    $search = $c->stash->{search};

    if(defined($json = $search->seq_by_id($schema, $c->req->path, $c->req->params, $id_seq))) {
        $c->stash(json => $json);
    }
    else {
        # FIXME - return a more informative error
        $c->forward('default');
    }
}

sub seq_by_id_cgi :Chained('seq') :PathPart('') :Args(0) {
    my($self, $c) = @_;

    # to allow backwards compatibility with old, more 'cgi style', URLs:
    # '/seq?id=*' rather than '/seq/*'

    $self->seq_by_id($c, $c->req->params->{id});
}


=head2 frag_hit

=cut

sub frag_hit :Chained('base') : PathPart('frag_hit') :Args(0) {
    my($self, $c) = @_;

    my $schema;
    my $search;
    my $json;

    $schema = $c->stash->{collection}->schema;
    $search = $c->stash->{search};

    if(defined($json = $search->frag_hit($schema, $c->req->path, $c->req->params))) {
        $c->stash(json => $json);
    }
    else {
        # FIXME - return a more informative error
        $c->forward('default');
    }
}

=head2 contact_hit

=cut

sub contact_hit :Chained('base') :PathPart('contact_hit') :CaptureArgs(0) {
    my($self, $c) = @_;

    $c->stash(template => 'contact_hit.tt', colours => $colours);
}

sub contact_hit_by_id :Chained('contact_hit') :PathPart('') :Args(1) {
    my($self, $c, $id) = @_;

    my $schema;
    my $search;
    my $json;
    my $ids;

    $schema = $c->stash->{collection}->schema;
    $search = $c->stash->{search};

    $ids = [split /,/, $id];
    if(@{$ids} == 1) {
        if(defined($json = $search->contact_hit_by_id($schema, $c->req->path, $c->req->params, $id))) {
            $c->stash(json => $json);
        }
        else {
            # FIXME - return a more informative error
            $c->forward('default');
        }
    }
    else {
        if(defined($json = $search->contact_hits_by_ids($schema, $c->req->path, $c->req->params, $ids, $json))) {
            $c->stash(template => 'contact_hits.tt');
            $c->stash(json => $json);
        }
        else {
            # FIXME - return a more informative error
            $c->forward('default');
        }
    }
}

sub contact_hit_by_id_cgi :Chained('contact_hit') :PathPart('') :Args(0) {
    my($self, $c) = @_;

    # to allow backwards compatibility with old, more 'cgi style', URLs:
    # '/seq?id=*' rather than '/seq/*'

    $self->contact_hit_by_id($c, $c->req->params->{id});
}

=head2 queue_stats

=cut

sub queue_stats  :Chained('base') :PathPart('queue_stats') :Args(0) {
    my($self, $c) = @_;

    my $schema;
    my $rs_job;
    my $stats;
    my $json;

    $schema = $c->stash->{collection}->schema;
    $stats = defined($rs_job = $schema->resultset('Job')) ? $rs_job->stats : undef;
    $c->stash(template => 'queue_stats.tt');
    $c->stash(queue_stats => $stats);
}

########## FIXME - old code, should be updated and/or moved to Fist::Utils::Search ##########

=head2 frag

=cut

sub frag :Local {
    my($self, $c) = @_;

    my $id;
    my $frag;

    if(defined($id = $c->req->params->{id})) {
        $frag = $c->stash->{collection}->resultset('Frag')->find({id => $id});
    }

    $c->stash(
              template    => 'frag.tt',

              json        => {
                              # storing everything I want to return in this hash called 'json'
                              # so that I can ignore everything else using 'expose_stash' in Fist.pm

                              server_url => $c->request->base->as_string,

                              # don't nest hashes as this means multiple copies of some data.
                              # eg. each query sequence is used three times: once for the contact_hit, once
                              # for the hsp with the template, and once for the hsp with the other query.

                              frag => $frag,
                             },
             );
}

=head2 interprets

=cut

sub interprets :Local {
    my($self, $c) = @_;

    my $text;
    my @F;
    my $f;
    my $aliases;
    my $alias;
    my $pos;
    my $results;
    my $seq_result;
    my $seqs;
    my $seq;
    my $ids_seqs;
    my $posns;
    my @contact_hits;
    my $contact_hit;
    my $best_interprets;
    my $feature_inst;
    my $feature;
    my $pfams;
    my @feature_contacts;
    my $feature_contact;

    $results = {
                seqs          => [],
                features      => {},
                interprets    => [],
                pfam_contacts => [],
               };

    $c->stash(collection => $c->model('FistDB'));

    $ids_seqs = {};
    if(defined($text = $c->req->params->{search})) {
        $aliases = {};
        @F = split /\s+/, $text;
        $alias = undef;
        foreach $f (@F) {
            if(defined($alias) and ($f =~ /\A\d+\Z/)) {
                $pos = $f;
                $aliases->{$alias}->{$pos}++;
            }
            else {
                $alias = $f;
                defined($aliases->{$alias}) or ($aliases->{$alias} = {});
            }
        }

        foreach $alias (sort keys %{$aliases}) {
            $posns = [sort {$a <=> $b} keys %{$aliases->{$alias}}];
            $seqs = [
                     $c->stash->{collection}->resultset('Seq')->search(
                                                                       {
                                                                        'aliases.alias' => $alias,
                                                                        'aliases.type'  => 'UniProtKB accession', # FIXME - do not hardcode this
                                                                       },
                                                                       {
                                                                        join => 'aliases',
                                                                        prefetch => {feature_insts => 'feature'},
                                                                       }
                                                                      )->all
                    ];

            foreach $seq (@{$seqs}) {
                $ids_seqs->{$seq->id}++;

                $seq_result = {
                               query             => $alias,
                               primary_id        => $seq->primary_id,
                               name              => $seq->name,
                               seq               => $seq->seq,
                               len               => $seq->len,
                               feature_instances => {},
                              };

                foreach $feature_inst ($seq->feature_insts) {
                    $feature = $feature_inst->feature;
                    defined($results->{features}->{$feature->source}) or ($results->{features}->{$feature->source} = {});
                    if(!defined($results->{features}->{$feature->source}->{$feature->ac_src})) {
                        $results->{features}->{$feature->source}->{$feature->ac_src} = {
                                                                                        id_src        => $feature->id_src,
                                                                                        ac_src        => $feature->ac_src,
                                                                                        description   => $feature->description,
                                                                                       }
                    }

                    ($feature->source eq 'Pfam') and $pfams->{$feature->id}++;

                    defined($seq_result->{feature_instances}->{$feature->source}) or ($seq_result->{feature_instances}->{$feature->source} = []);
                    push @{$seq_result->{feature_instances}->{$feature->source}}, {
                                                                                   ac_src        => $feature->ac_src,
                                                                                   seq_start     => $feature_inst->start_seq,
                                                                                   seq_end       => $feature_inst->end_seq,
                                                                                   e_value       => $feature_inst->e_value,
                                                                                   score         => $feature_inst->score,
                                                                                   true_positive => $feature_inst->true_positive,
                                                                                  };
                }

                push @{$results->{seqs}}, $seq_result;
            }
        }
        $pfams = [keys %{$pfams}];

        if(@{$pfams} > 0) {
            @feature_contacts = $c->model('FistDB')->resultset('FeatureContact')->search({id_feat1 => {in => $pfams}, id_feat2 => {in => $pfams, '>=' => 'id_feat1'}})->all;
            foreach $feature_contact (@feature_contacts) {
                push @{$results->{pfam_contacts}}, [$feature_contact->feature1->ac_src, $feature_contact->feature2->ac_src];
            }
        }

        $ids_seqs = [sort {$a <=> $b} keys %{$ids_seqs}];
        if(@{$ids_seqs} > 0) {
            @contact_hits = $c->model('FistDB')->resultset('ContactHit')->search(
                                                                                 {
                                                                                  id_seq_a1 => $ids_seqs,
                                                                                  id_seq_b1 => $ids_seqs,
                                                                                 },
                                                                                 {
                                                                                  prefetch => [
                                                                                               'seq_a1',
                                                                                               'seq_b1',
                                                                                               {frag_inst_a2 => {frag => 'pdb'}},
                                                                                               'frag_inst_b2',
                                                                                              ],
                                                                                 },
                                                                                )->all;
            foreach $contact_hit (@contact_hits) {
                $best_interprets = $contact_hit->best_interprets;

                push @{$results->{interprets}}, {
                                                 idContactHit   => $contact_hit->id,

                                                 proteinA       => $contact_hit->seq_a1->primary_id,
                                                 startProteinA  => $contact_hit->start_a1,
                                                 endProteinA    => $contact_hit->end_a1,

                                                 proteinB       => $contact_hit->seq_b1->primary_id,
                                                 startProteinB  => $contact_hit->start_b1,
                                                 endProteinB    => $contact_hit->end_b1,

                                                 pdb            => $contact_hit->frag_inst_a2->frag->pdb->idcode,
                                                 assembly       => $contact_hit->frag_inst_a2->assembly,

                                                 modelA         => $contact_hit->frag_inst_a2->model,
                                                 templateA      => $contact_hit->frag_inst_a2->dom,
                                                 startTemplateA => $contact_hit->start_a2,
                                                 endTemplateA   => $contact_hit->end_a2,

                                                 modelB         => $contact_hit->frag_inst_b2->model,
                                                 templateB      => $contact_hit->frag_inst_b2->dom,
                                                 startTemplateB => $contact_hit->start_b2,
                                                 endTemplateB   => $contact_hit->end_b2,

                                                 pcidA          => $contact_hit->pcid_a,
                                                 eValueA        => $contact_hit->e_value_a,

                                                 pcidB          => $contact_hit->pcid_b,
                                                 eValueB        => $contact_hit->e_value_b,

                                                 nResRes        => $contact_hit->n_resres_a1b1,

                                                 interprets     =>
                                                 defined($best_interprets)
                                                 ? {
                                                    rand => $best_interprets->rand,
                                                    raw  => $best_interprets->raw,
                                                    mean => $best_interprets->mean,
                                                    sd   => $best_interprets->sd,
                                                    z    => $best_interprets->z,
                                                   }
                                                 : {
                                                     rand => undef,
                                                     raw  => undef,
                                                     mean => undef,
                                                     sd   => undef,
                                                     z    => undef,
                                                 },

                                                };
            }
        }
    }

    $c->stash(
              template => 'search.tt',
              json     => {
                           seqs          => $results->{seqs},
                           features      => $results->{features},
                           interprets    => $results->{interprets},
                           pfam_contacts => $results->{pfam_contacts},
                          },
             );
}

=head2 interprets_json

=cut

sub interprets_json :Local {
    my($self, $c) = @_;

    $c->forward('interprets');
    $c->stash->{current_view} = 'JSON';
}

=head2 pfam_contacts

=cut

sub pfam_contacts :Local {
    my($self, $c) = @_;

    my $text;
    my $acs_src;
    my $ac_src;
    my @features;
    my $feature;
    my @feature_contacts;
    my $feature_contact;
    my $ids_features;
    my @feature_inst_contacts;
    my $feature_inst_contact;
    my $pfam_contacts;

    $pfam_contacts = [];
    if(defined($text = $c->req->params->{search})) {
        $acs_src = {};

        foreach $ac_src (split /\s+/, $text) {
            $acs_src->{$ac_src}++;
        }
        $acs_src = [sort keys %{$acs_src}];

        if(@{$acs_src} > 0) {
            # FIXME - generalise to other sources of features
            @features = $c->model('FistDB')->resultset('Feature')->search({source => 'pfam', ac_src => {in => $acs_src}})->all;
            foreach $feature (@features) {
                $ids_features->{$feature->id}++;
            }
            $ids_features = [sort {$a <=> $b} keys %{$ids_features}];

            @feature_contacts = $c->model('FistDB')->resultset('FeatureContact')->search(
                                                                                         {
                                                                                          id_feat1 => {in => $ids_features},
                                                                                          id_feat2 => {in => $ids_features, '>=' => 'id_feat1'},
                                                                                         },
                                                                                         {
                                                                                          prefetch => [
                                                                                                       'id_feat1',
                                                                                                       'id_feat2',
                                                                                                      ],
                                                                                         },
                                                                                        )->all;
            foreach $feature_contact (@feature_contacts) {
                @feature_inst_contacts = $c->model('FistDB')->resultset('FeatureInstContact')->search(
                                                                                                      {
                                                                                                       'id_feat_inst1.id_feature' => $feature_contact->feature1->id,
                                                                                                       'id_feat_inst2.id_feature' => $feature_contact->feature2->id,
                                                                                                      },
                                                                                                      {
                                                                                                       join => [
                                                                                                                {id_feat_inst1 => 'id_feature'},
                                                                                                                {id_feat_inst2 => 'id_feature'},
                                                                                                               ],
                                                                                                       prefetch => [
                                                                                                                    {id_frag_inst1 => {id_frag => 'idcode'}},
                                                                                                                    {id_frag_inst2 => {id_frag => 'idcode'}},
                                                                                                                   ],
                                                                                                      }
                                                                                                     )->all;
                foreach $feature_inst_contact (@feature_inst_contacts) {
                    push @{$pfam_contacts}, {
                                             ac_pfam1 => $feature_contact->feature1->ac_src,
                                             ac_pfam2 => $feature_contact->feature2->ac_src,

                                             pdb      => $feature_inst_contact->frag_inst1->frag->pdb->idcode,
                                             assembly => $feature_inst_contact->frag_inst1->assembly,

                                             model1   => $feature_inst_contact->frag_inst1->model,
                                             dom1     => $feature_inst_contact->frag_inst1->frag->dom,
                                             start1   => $feature_inst_contact->feat_inst1->start_seq,
                                             end1     => $feature_inst_contact->feat_inst1->end_seq,
                                             e_value1 => $feature_inst_contact->feat_inst1->e_value,

                                             model2   => $feature_inst_contact->frag_inst2->model,
                                             dom2     => $feature_inst_contact->frag_inst2->frag->dom,
                                             start2   => $feature_inst_contact->feat_inst2->start_seq,
                                             end2     => $feature_inst_contact->feat_inst2->end_seq,
                                             e_value2 => $feature_inst_contact->feat_inst2->e_value,

                                             n_resres => $feature_inst_contact->n_resres,
                                            };
                }
            }

        }
    }

    $c->stash(
              template => 'search.tt',
              json     => {
                           pfam_contacts => $pfam_contacts,
                          },
             );
}

=head2 pfam_contacts_json

=cut

sub pfam_contacts_json :Local {
    my($self, $c) = @_;

    $c->forward('pfam_contacts');
    $c->stash->{current_view} = 'JSON';
}

############################################################################################


=head2 default

Standard 404 error page

=cut

sub default :Path {
    my ($self, $c) = @_;
    $c->response->body('Page not found');
    $c->response->status(404);
}

=head2 error

=cut

sub error :Path {
    my($self, $c) = @_;

    $c->stash(template => 'error.tt');
}

=head2 end

Attempt to render a view, if needed.

=cut

sub end : ActionClass('RenderView') {
    my($self, $c) = @_;

    my $errors;
    my $path;

    $errors = scalar @{$c->error};
    if($errors) {
        $c->res->status(500);
        $c->res->body(@{$c->error});
        $c->clear_errors;
    }

    if(ref $c->stash->{json} eq 'HASH') {
        if($c->stash->{json}->{path_reset}) {
            $c->stash->{json}->{path} = '';
        }
        else {
            $c->stash->{json}->{path} = ($c->req->path =~ /\A(\S*search\/id\/[^\/]+)/) ? "/$1" : '';
        }
    }
}

=head1 PRIVATE METHODS

=cut

=head2 set_view

=cut

sub set_view :Private {
    my($self, $c, $type) = @_;

    if($type eq 'json') {
        $c->stash->{current_view} = 'JSON';
    }
    elsif($type eq 'tsv') {
        # FIXME - add tab-delimited view here
    }
    else {
        # default is 'tt' for Template Toolkit, i.e. the normal HTML view
    }
}

=head2 json_from_search_id

=cut

sub json_from_search_id :Private {
    my($c, $id_search, $suffix) = @_;

    my $dn_search;
    my $json;
    my $fn_search;
    my $fh_search;
    my $json_str;

    defined($suffix) or ($suffix = '.json');

    # get json from file
    $dn_search = defined($c->config->{dn_search}) ? $c->config->{dn_search} : '/tmp/';
    $fn_search = join '', $dn_search, $id_search, '/', $id_search, $suffix;
    (-e $fn_search) or ($fn_search .= '.gz');
    if(-e $fn_search) {
        if(!defined($json = Fist::Utils::Search::read_json_file($fn_search))) {
            $c->stash(error => "The output for the job with id = '$id_search' could not be read. Your job may have been deleted. Please run it again and/or <a href='/about#contactUs'>contact us</a> if you have problems.");
            $c->forward('error');
        }
        else {
            # this overrides dn_search already read in from the json file, done
            # since the search results may have been moved from a previous location
            $json->{params}->{given}->{dn_search} = $dn_search;
        }
    }
    else {
        $c->stash(error => "Output for the job with id = '$id_search' was not found. Your job may have been deleted. Please run it again and/or <a href='/about#contactUs'>contact us</a> if you have problems.");
        $c->forward('error');
    }

    return $json;
}

=head1 AUTHOR

Matthew Betts

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
