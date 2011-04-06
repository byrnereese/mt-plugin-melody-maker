package MelodyMaker::Tags;

use strict;

sub _render_status_widget {
    my ($widget, $ctx) = @_;
    my $app = MT->instance;
    my $tmpl_name = $widget->{template};
    my $p = $widget->{plugin};
    my $tmpl;
    if ($p) {
        $tmpl = $p->load_tmpl($tmpl_name);
    } else {
        # Just in case...
        $tmpl = $app->load_tmpl($tmpl_name);
    }
    next unless $tmpl;
    $tmpl->context( $ctx );
    my $param = {};
#    local $param->{blog_id}         = $blog_id;
    if ( my $h = $widget->{code} || $widget->{handler} ) {
        $h = $app->handler_to_coderef($h);
        $h->( $app, $tmpl, $param );
    }
    return $app->build_page( $tmpl, $param );
}

sub status_widgets {
    my ( $ctx, $args, $cond ) = @_;

    my $app = MT->instance;
    my $blog = $app->can('blog') ? $app->blog : $ctx->stash('blog');
    my $blog_id = $blog ? $blog->id : 0;

#    my $perms = $app->user->permissions;
#    require JSON;
#    my $prefs = JSON::jsonToObj( $perms->ui_prefs );
#    my @collapsed = split(',',$prefs->{'collapsed'});

    my $widgets = $app->registry('status_widgets');
    my $vars = $ctx->{__stash}{vars};
    my $builder = $ctx->stash('builder');
    my $tokens  = $ctx->stash('tokens');
    my $out = '';
    foreach my $id (keys %$widgets) {
        my $widget = $widgets->{$id};
        if ( my $cond = $widget->{condition} ) {
            if ( !ref($cond) ) {
                $cond = $widget->{condition} = $app->handler_to_coderef($cond);
            }
            next unless $cond->();
        }
        my $scope = $widget->{'scope'} || '';
        my $sys_only = $scope eq 'system' ? 1 : 0;
        my ($html,$count,$link);
        if ($widget->{'template'}) {
            $html = _render_status_widget( $widget, $ctx );
        } else {
            if ( $widget->{mode} ) {
                $link = $app->uri(
                    mode => $widget->{mode},
                    args => {
                        %{ $widget->{args} || {} },
                        (   $blog_id && !$sys_only 
                            ? ( blog_id => $blog_id )
                            : ()
                        )
                    }
                    );
            }
            my $counter = $widget->{'count_handler'};
            if ( !ref($counter) ) {
                $counter = $widget->{count_handler} = $app->handler_to_coderef($counter);
            }
            $count = $counter->( $app, $ctx );
        }
        local $vars->{count}       = $count;
        local $vars->{label}       = $widget->{label};
        local $vars->{link}        = $link;
        local $vars->{widget_html} = $html;
        my $res = $builder->build( $ctx, $tokens, $cond );
        return $ctx->error( $builder->errstr ) unless defined $res;
        $out .= $res;
    }
    return $out;
}

1;
