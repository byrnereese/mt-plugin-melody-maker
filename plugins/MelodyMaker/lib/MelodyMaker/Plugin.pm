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
    return 1;
}

sub status_comments {
    my ($ctx) = @_;
    my $app = MT->instance;
    my $blog = $app->can('blog') ? $app->blog : $ctx->stash('blog');
    my $count = MT->model('comment')->count({
        ($blog ? (blog_id => $blog->id) : ()),
        visible => 0,
        junk_status => MT->model('comment')->NOT_JUNK(),
    });
    return $count;
}

1;
