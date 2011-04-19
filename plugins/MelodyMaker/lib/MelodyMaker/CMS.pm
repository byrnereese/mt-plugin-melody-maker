package MelodyMaker::CMS;

use strict;
use File::Spec::Functions;
use Digest::SHA1 qw( sha1_base64 );
use MT::Util qw( encode_url );

sub _build_blog_loop {
    my ($app,$blogs) = @_;
    my $auth = $app->user or return;
    my @data = ();
    if ($blogs) {
        for my $blog (@$blogs) {
            next unless $blog;
            my $logo = $blog->meta('logo_url');
            push @data,
              { top_blog_id   => $blog->id, 
                top_blog_name => $blog->name, 
                top_blog_url  => $blog->site_url, 
                ( $logo ? (top_blog_logo => $logo) : () ) };
        }
    }
    return \@data;
}

sub build_blog_selector {
    my ($ctx, $args, $cond) = @_;
    my $app     = MT->instance;
    my $q       = $app->query;

    my $param = {};

    my $blog = $app->blog;
    my $blog_id = $blog ? $blog->id : 0;

    $param->{dynamic_all} = $blog->custom_dynamic_templates eq 'all' if $blog;

    my $blog_class = MT->model('blog');
    my $auth = $app->user or return;

    my $perms = $app->user->permissions;

    my @faves;
    my $fave_data;
    if ($perms) {
        require JSON;
        my $prefs     = JSON::from_json($perms->ui_prefs);
        my $favorites = $prefs->{favorites};
        @faves        = split(',',$favorites);
        if (@faves) {
            my @blogs     = $blog_class->load( { id => \@faves } );
            # Sort blogs. Since it is a small list, let's just do a brute force sort
            my %blogs = map { $_->id => $_ } @blogs;
            @blogs = ();
            for (@faves) { push @blogs, $blogs{ $_ }; }
            $fave_data = _build_blog_loop($app,\@blogs);
            $param->{fave_blog_count} = $#faves + 1;
        }
    }

    # REMOVE FROM MELODY MAKER?
    # Any access to a blog will put it on the top of your
    # recently used blogs list (the blog selector)
    $app->add_to_favorite_blogs($blog_id) if $blog_id;

    my %args;
    $args{join} =
      MT::Permission->join_on(
                               'blog_id',
                               {
                                  author_id   => $auth->id,
                                  permissions => { not => "'comment'" }
                               }
      );
    $args{limit} = $app->blog ? 6 : 5;    # don't load more than 6
    my @blogs = $blog_class->load( { (@faves ? (id => { not => \@faves }) : ()) }, \%args );

    # This grouping of fav_blogs is carried over from Movable Type
    # The list is maintained based upon the most recently viewed list
    # of blogs.
    # Melody Maker's concept of favorite blogs is more about bookmarking
    # them. It is maintained manually.
    my @accessed_blogs = @{ $auth->favorite_blogs || [] };
    @accessed_blogs = grep { $_ != $blog_id } @accessed_blogs if $blog_id;

    # Special case for when a user only has access to a single blog.
    if (    ( !defined( $blog_id ) )
         && ( @blogs == 1 )
         && ( scalar @accessed_blogs <= 1 ) )
    {

        # User only has visibility to a single blog. Don't
        # bother giving them a dashboard link for 'all blogs', or
        # to 'select a blog'.
        $param->{single_blog_mode} = 1;
        my $blog = $blogs[0];
        $blog_id = $blog->id;
        my $perms = MT::Permission->load(
                            { blog_id => $blog_id, author_id => $auth->id } );
        if ( !$app->blog ) {
            if ( $app->mode eq 'dashboard' ) {
                $q->param( 'blog_id', $blog_id );
                $param->{blog_id}   = $blog_id;
                $param->{blog_name} = $blog->name;
                $app->permissions($perms);
                $app->blog($blog);
            }
            else {
                @accessed_blogs = ($blog_id);
                $blog_id   = undef;
            }
        }
    } ## end if ( ( !defined( $q->param...)))
    elsif ( @blogs && ( @blogs <= 5 ) ) {

        # This user only has visibility to 5 or fewer blogs;
        # no need to reference their 'favorite' blogs list.
        my @ids = map { $_->id } @blogs;
        if ($blog_id) {
            @ids = grep { $_ != $blog_id } @ids;
        }
        @accessed_blogs = @ids;
        if ( $auth->is_superuser ) {

            # Better check to see if there are more than
            # 10 blogs in the system; if so, a superuser
            # will still want the 'Select a blog...' chooser.
            # Otherwise, hide it.
            my $all_blog_count = $blog_class->count();
            if ( $all_blog_count < 11 ) {
                $param->{selector_hide_chooser} = 1;
            }
        }
        else {

            # This user is not a superuser and only has
            # 10 blogs, so they don't need a 'select blog'
            # link...
            $param->{selector_hide_chooser} = 1;
        }
    } ## end elsif ( @blogs && ( @blogs...))
    $param->{selector_hide_chooser} ||= 0;

    # Logic for populating the blog selector control
    #   * Pull list of 'favorite blogs' from user record
    #   * Load all of those blogs so we can display them
    #   * Exclude the current blog from the favorite list so it isn't
    #     shown twice.
    @blogs = $blog_class->load( { id => \@accessed_blogs, ( @faves ? (id => { not => \@faves }) : () ) } ) if @accessed_blogs;
    my %blogs = map { $_->id => $_ } @blogs;
    @blogs = ();
    foreach my $id (@accessed_blogs) {
        use Data::Dumper;
        push @blogs, $blogs{$id} if $blogs{$id};
    }

    my $all_blog_count = $blog_class->count();
    $param->{all_blog_count} = $all_blog_count;

    my @blog_data = @{ _build_blog_loop($app,\@blogs) };

    $param->{top_blog_loop} = \@blog_data;
    $param->{fave_blog_loop} = $fave_data;

    if ( !$app->user->can_create_blog
         && ( $param->{single_blog_mode} || scalar(@blog_data) <= 1 ) )
    {
        $param->{no_submenu} = 1;
    }
    my $plugin = MT->component('MelodyMaker');
    my $tmpl = $plugin->load_tmpl( 'include/blog_selector.tmpl' );
    $tmpl->param($param);
    return $tmpl->output( );
}

sub upload_blog_logo {
    my $app = shift;

    require MT::CMS::Asset;
    my ( $asset, $bytes )
      = MT::CMS::Asset::_upload_file( $app, @_, require_type => 'image', );
    return if !defined $asset;
    return $asset if !defined $bytes;    # whatever it is

    ## TODO: should this be layered into _upload_file somehow, so we don't
    ## save the asset twice?
    my $user_id = $app->user->id;

    $asset->tags('@bloglogo');
    $asset->created_by($user_id);
    $asset->save;

    $app->forward( 'asset_blog_logo',
                   { asset => $asset } );
} ## end sub upload_blog_logo

sub _blog_logo_html {
    my ($app, $asset) = @_;
    return '';
}

sub asset_blog_logo {
    my $app = shift;
    my ($param) = @_;
    my $blog = $app->blog;

    my ($id, $asset);
    if ($asset = $param->{asset}) {
        $id = $asset->id;
    }
    else {
        $id = $param->{asset_id} || scalar $app->query->param('id');
        $asset = $app->model('asset')->lookup($id);
    }

    my $thumb_html = _blog_logo_html( $app, $asset );

    # Delete the blog's logo thumb (if any); it'll be regenerated.
    if ($blog->meta('logo_asset_id') != $asset->id) {
        my $old_asset = MT->model('asset')->load( $blog->meta('logo_asset_id') );
        if ($old_asset) {
            my $old_file = $old_asset->file_path();
            my $fmgr = MT::FileMgr->new('Local');
            if ($fmgr->exists($old_file)) {
                $fmgr->delete($old_file);
            }
        }
        $blog->meta('logo_asset_id',$asset->id);
        my ( $url, $w, $h ) = $asset->thumbnail_url( Width => 38, Square => 1 );
        $blog->meta('logo_url',$url);
        $blog->save;
    }

    $app->load_tmpl(
        'dialog/asset_blog_logo.tmpl',
        {
            asset_id    => $id,
            edit_field  => $app->query->param('edit_field') || '',
            blog_logo   => $thumb_html,
        },
    );
}

sub _ui_prefs_from_params {
    my $app  = shift;
    my $q    = $app->query;
    my %prefs;
    if (my $exp  = $q->param('collapsed')) {
        $prefs{'collapsed'} = $exp;
    }
    if (my $fav  = $q->param('favorites')) {
        if ($fav eq 'none') {
            $prefs{'favorites'} = '';
        } else {
            $prefs{'favorites'} = $fav;
        }
    }
    \%prefs;
} ## end sub _ui_prefs_from_params

sub _send_json_response {
    my ( $app, $result ) = @_;
    require JSON;
    my $json = JSON::to_json($result);
    $app->send_http_header("");
    $app->print($json);
    return $app->{no_print_body} = 1;
    return undef;
} ## end _send_json_response

sub save_ui_prefs {
    my $app   = shift;
    my $perms = $app->user->permissions
        or return _send_json_response( $app, { 'error' => $app->translate("No permissions") });
    $app->validate_magic() 
        or return _send_json_response( $app, { 'error' => $app->translate("Invalid magic") });
    require JSON;
    my $prefs = JSON::from_json($perms->ui_prefs);
    my $new   = _ui_prefs_from_params($app);
    MT::__merge_hash( $prefs, $new, 1 );
    $perms->ui_prefs( JSON::to_json($prefs) );
    $perms->save
        or return _send_json_reponse( $app, { 'error' => $app->translate( "Saving permissions failed: [_1]", $perms->errstr ) });
    return _send_json_response( $app, { 'success' => 1 });
} ## end save_ui_prefs 

1;
__END__

=head1 NAME

MelodyMaker::CMS

=head1 METHODS

=head2 _ui_prefs_from_params

This method processes the input parameters from the POST method and returns an encoded string
containing all of the users stated UI preferences.

=head2 _send_json_response

This method takes two input parameters: $app and a $hash. It then encodes the $hash as a JSON
data structure and sends it back over the wire with the proper HTTP headers etc.

=head2 save_ui_prefs

This method is responsible for saving the state of the user interface whenever it is changed.
It is invoked via javascript automatically and stashes the state of collapsed and expanded 
menus.

=head1 AUTHOR & COPYRIGHT

Please see L<MT/AUTHOR & COPYRIGHT>.

=cut



