package MelodyMaker::Plugin;

use strict;

sub init_app {
    my $cb     = shift;
    my ($app)  = @_;
    require MelodyMaker::CMS;
    my $r = $app->registry;
#    return if $app->query->param('noui');
    my $selector = $r->{'blog_selector'};
    $selector->{code} = sub { &MelodyMaker::CMS::build_blog_selector; };
    return 1;
}

sub init_request {
    my $cb     = shift;
    my $plugin = $cb->plugin;
    my ($app)  = @_;
    return if $app->id ne 'cms';
    return unless $app->isa('MT::App::CMS');
    return if $app->query->param('noui');
    $app->config('AltTemplatePath', $plugin->path . '/tmpl');
    return 1;
}

1;
