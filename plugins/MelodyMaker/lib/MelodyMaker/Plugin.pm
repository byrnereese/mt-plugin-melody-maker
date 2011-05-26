package MelodyMaker::Plugin;

use strict;

sub init_app {
    my $cb     = shift;
    my ($app)  = @_;
    return unless $app->isa('MT::App::CMS');
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
    return if $app->id !~ /(cms|wizard|upgrade)/;
    return unless $app->isa('MT::App::CMS') || $app->isa('MT::App::Upgrader') || $app->isa('MT::App::Wizard');
    return if $app->query->param('noui');
    $app->config('AltTemplatePath', $plugin->path . '/tmpl');
    return 1;
}

1;
