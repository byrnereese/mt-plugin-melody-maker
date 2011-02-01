package MelodyMaker::Plugin;

use strict;

sub init_request {
    my $cb     = shift;
    my $plugin = $cb->plugin;
    my ($app)  = @_;
    return if $app->id ne 'cms';
    return unless $app->isa('MT::App::CMS');
    $app->config('AltTemplatePath', $plugin->path . '/tmpl');
    return 1;
}

1;
