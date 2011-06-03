package MelodyMaker::Callbacks;

use strict;
use MT::Util;

sub header_param {
    my ($cb, $app, $param, $tmpl) = @_;
    my $perms = $app->user->permissions;
    require JSON;
    my $pref_str = $perms && $perms->ui_prefs ? $perms->ui_prefs : '{}';
    my $prefs = JSON::from_json( $pref_str );
    my $coll = $prefs->{'collapsed'} || '';
    my @collapsed = split(',',$coll);
    my $menus = $app->registry('menus');
    foreach my $id (@collapsed) {
        $id =~ s/-menu//;
        $menus->{$id}->{collapsed} = 1;
    }
    if ($app->blog && $app->blog->meta('logo_asset_id')) {
        my $aid = $app->blog->meta('logo_asset_id');
        my $asset = MT->model('asset')->load( $aid );
        next unless $asset;
        my ( $url, $w, $h ) = $asset->thumbnail_url( Width => 56, Square => 1 );
        $param->{'blog_logo_url'} = $url;
    }
    return 1;
} ## end header_param 

sub blog_settings_param {
    my ($cb, $app, $param, $tmpl) = @_;

    my $where  = 'insertAfter';
    my $marker = 'has-license';
    # Marker can contain either a node or an ID of a node
    unless(ref $marker eq 'MT::Template::Node') {
        $marker = $tmpl->getElementById($marker);
    }

    my $setting = $tmpl->createElement('app:setting');
    $setting->setAttribute('label','Site Icon');
    $setting->setAttribute('id','site-logo');
    $setting->setAttribute('show_hint',1);
    $setting->setAttribute('hint','Upload a square image to be associated with this site.');
    $setting->innerHTML( _get_html($app, 'cfg_blog_logo.tmpl', $tmpl->param) );
    $tmpl->$where($setting, $marker);
} ## end blog_settings_param

sub _get_html {
    my ($app, $tmpl_name, $param) = @_;

    my $plugin = MT->component("MelodyMaker");
    my $snip_tmpl = $plugin->load_tmpl($tmpl_name) or die $plugin->errstr;
    return q() unless $snip_tmpl;

    my $tmpl;
    if ( ref $snip_tmpl ne 'MT::Template' ) {
        $tmpl = MT->model('template')->new(
            type   => 'scalarref',
            source => ref $snip_tmpl ? $snip_tmpl : \$snip_tmpl
            );
    }
    else {
        $tmpl = $snip_tmpl;
    }

    my $ctx = $tmpl->context;
    my $blog = $app->blog;
    $param->{blog_id} = $blog->id;
    if (my $asset_id = $blog->meta('logo_asset_id')) {
        $param->{blog_logo_asset_id} = $blog->meta('logo_asset_id');
        $param->{blog_logo} = $blog->meta('logo_asset_id');
        my $asset = MT->model('asset')->load( $asset_id );
        $ctx->stash('asset',$asset);
    }
    my $html = $tmpl->output( $param )
        or die $tmpl->errstr;
    $html =~ s/<\/?form[^>]*?>//gis;  # strip any enclosure form blocks
    $html = $plugin->translate_templatized($html);
    $html;
}

1;
__END__

=head1 NAME

MelodyMaker::Callbacks

=head1 METHODS

=head2 header_param

This method is a callback handler for the template_param callback associated with the
apps main header include. It is responsible for seeding the template with the necessary
UI state paramters, like what menus are expanded and collapsed.

This works not in the traditional fashion for a callback. It modifies the registery
directly because changing the template context did not seem to work. This should be 
thread safe as far as I know.

=head1 AUTHOR & COPYRIGHT

Please see L<MT/AUTHOR & COPYRIGHT>.

=cut



