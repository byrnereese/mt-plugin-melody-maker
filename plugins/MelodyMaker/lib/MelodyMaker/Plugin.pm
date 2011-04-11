package MelodyMaker::Plugin;

use strict;

sub init_request {
    my $cb     = shift;
    my $plugin = $cb->plugin;
    my ($app)  = @_;
    return if $app->id ne 'cms';
    return unless $app->isa('MT::App::CMS');
    return if $app->query->param('noui');
    $app->config('AltTemplatePath', $plugin->path . '/tmpl');

    my $selector = $app->registry('blog_selector');
    $selector->{code} = '$MelodyMaker::MelodyMaker::CMS::build_blog_selector';
    return 1;
}

1;
