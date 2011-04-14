package MelodyMaker::CMS;

use strict;
use File::Spec::Functions;
use Digest::SHA1 qw( sha1_base64 );
use MT::Util qw( encode_url );

sub _build_blog_loop {
    my ($app,$blogs) = @_;
    my $auth = $app->user or return;
    my @data;
    if ($blogs) {
#        my @perms
#          = grep { !$_->is_empty }
#          MT->model('permission')->load(
#                        { author_id => $auth->id, blog_id => \@fav_blogs, } );
#        my %perms = map { $_->blog_id => $_ } @perms;
        for my $blog (@$blogs) {
#            my $perm = $perms{ $blog->id };
#            next unless $auth->is_superuser || ( $perm && !$perm->is_empty );
            push @data,
              { top_blog_id => $blog->id, top_blog_name => $blog->name, top_blog_url => $blog->site_url };
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
    my $blog_id = $blog->id if $blog;

    $param->{dynamic_all} = $blog->custom_dynamic_templates eq 'all' if $blog;

    my $blog_class = MT->model('blog');
    my $auth = $app->user or return;

    my $perms = $app->user->permissions;

    my $fave_blog_data;
    if ($perms) {
        require JSON;
        my $prefs     = JSON::from_json($perms->ui_prefs);
        my $favorites = $prefs->{favorites};
        my @faves     = split(',',$favorites);
        my @blogs     = $blog_class->load( { id => \@faves } ) if @faves;
        $fave_blog_data = _build_blog_loop($app,\@blogs);
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
    $args{limit} = 6;    # don't load more than 6
    my @blogs = $blog_class->load( undef, \%args );

    # This grouping of fav_blogs is carried over from Movable Type
    # The list is maintained based upon the most recently viewed list
    # of blogs.
    # Melody Maker's concept of favorite blogs is more about bookmarking
    # them. It is maintained manually.
    my @fav_blogs = @{ $auth->favorite_blogs || [] };
    @fav_blogs = grep { $_ != $blog_id } @fav_blogs if $blog_id;

    # Special case for when a user only has access to a single blog.
    if (    ( !defined( $blog_id ) )
         && ( @blogs == 1 )
         && ( scalar @fav_blogs <= 1 ) )
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
                @fav_blogs = ($blog_id);
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
        @fav_blogs = @ids;
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
    @blogs = $blog_class->load( { id => \@fav_blogs } ) if @fav_blogs;
    my %blogs = map { $_->id => $_ } @blogs;
    @blogs = ();
    foreach my $id (@fav_blogs) {
        push @blogs, $blogs{$id} if $blogs{$id};
    }

    my $all_blog_count = $blog_class->count();
    $param->{all_blog_count} = $all_blog_count;

    my @blog_data = @{ _build_blog_loop($app,\@blogs) };
#    if (@blogs) {
#        my @perms
#          = grep { !$_->is_empty }
#          MT::Permission->load(
#                        { author_id => $auth->id, blog_id => \@fav_blogs, } );
#        my %perms = map { $_->blog_id => $_ } @perms;
#        for my $blog (@blogs) {
#            my $perm = $perms{ $blog->id };
#            next unless $auth->is_superuser || ( $perm && !$perm->is_empty );
#            push @blog_data,
#              { top_blog_id => $blog->id, top_blog_name => $blog->name, top_blog_url => $blog->site_url };
#            $blog_data[-1]{top_blog_selected} = 1
#              if $blog_id && ( $blog->id == $blog_id );
#        }
#    }
    $param->{top_blog_loop} = \@blog_data;
    $param->{fave_blog_loop} = $fave_blog_data;

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

sub ajax_upload {
    my $app   = shift;
    print STDERR "In ajax_upload\n";
    my ( $asset, $bytes ) = _upload_file( $app, undef, {
#        file_tmpl => 'support/uploads',
        field_name => 'file',
        root_path => '%s', # %s %a %r
    }) ;

    return _send_json_response( $app, { 
        "name" => $asset->file_name,
        "type" => $asset->mime_type,
        "size" => $bytes,
    });

} ## end ajax_upload

## Mostly copied from MT::App::CMS::Asset::_upload_file
## we have to make it more re-usable!!
sub _upload_file {
    my ( $app, $obj, $options ) = @_;
    print STDERR "In _upload_file\n";
    my $q = $app->query;
    my $blog      = MT->model('blog')->load( $q->param('blog_id') );
    my $blog_id   = $blog->id;
    print STDERR "Blog ID: " . $blog->id . "\n";
    my $fmgr      = $blog->file_mgr;
    my $root_path;
    my $base_url;
    # TODO - this seems like it should be a function of the file_tmpl. Is this the right structure for this?
    if ($options->{'root_path'} =~ /%s/) {
        $root_path = $app->static_file_path;
        $base_url  = $app->static_path;
    } elsif ($options->{'root_path'} =~ /%a/) {
        $root_path = $blog->archive_path;
        $base_url  = $blog->archive_url;
    } elsif ($options->{'root_path'} =~ /%r/) {
        $root_path = $blog->site_path;
        $base_url  = $blog->site_url;
    } else {
        print STDERR "ERROR: no root path determined!\n";
    }
    print STDERR "Root path: $root_path\n";
    print STDERR "Base URL: $base_url\n";
    print STDERR "Uploading file associated with: " . $blog->name . "\n";

    my ( $fh, $info ) = $app->upload_info( $options->{'field_name'} );

    my $mimetype;
    $mimetype = $info->{'Content-Type'} if ($info);

    # eval { $fh = $q->upload($field_name) };
    #           if ($@ && $@ =~ /^Undefined subroutine/) {
    #              $fh = $q->param($field_name);
    #           }

    my $basename = $q->param( $options->{'field_name'} );
    $basename =~ s!\\!/!g;    ## Change backslashes to forward slashes
    $basename =~ s!^.*/!!;    ## Get rid of full directory paths

    print STDERR "Basename: $basename\n";

    my $relative_path;
    my $file_tmpl = $options->{'file_tmpl'};
    if ( $file_tmpl ) {
        if ( $file_tmpl =~ m/\%[_-]?[A-Za-z]/ ) {
            if ( $file_tmpl =~ m/<\$?MT/i ) {
                $file_tmpl =~ s!(<\$?MT[^>]+?>)|(%[_-]?[A-Za-z])!$1 ? $1 : '<mt:FileTemplate format="'. $2 . '">'!gie;
            }
            else {
                $file_tmpl = qq{<mt:FileTemplate format="$file_tmpl">};
            }
        }
        require MT::Template::Context;
        my $ctx = MT::Template::Context->new;
        $ctx->{current_timestamp}     = $obj->created_on;
        local $ctx->{__stash}{blog}   = $blog;
        local $ctx->{__stash}{author} = $app->user;
        if ($obj) {
            my $obj_type  = $obj->class_type || $obj->datasource;
            local $ctx->{__stash}{$obj_type}        = $obj;
            local $ctx->{__stash}{archive_category} = $obj if $obj_type eq 'category';
        }
        require MT::Builder;
        my $build = MT::Builder->new;
        my $tokens = $build->compile( $ctx, $file_tmpl )
            or return $blog->error( $build->errstr() );
        unless ( $relative_path = $build->build( $ctx, $tokens ) ) {
            MT->log(
                { message => "Unable to translate the upload path you specified into a path on the file system. Check the options for the custom field associated with your slideshow: " . $build->errstr() } );
            return $blog->error( $build->errstr() );
        }
    } else { 
        my $digest = sha1_base64($fh);
        $digest =~ s{[/+]}{}g;
        $digest =~ s{(.......)}{$1,}g;
        my @dirs = split( /,/, $digest );
        $relative_path = File::Spec->catdir('support','uploads',@dirs);
    } ## end if ( $file_tmpl)
    print STDERR "Relative path: $relative_path\n";

    my $path;
    $path = File::Spec->catdir( $root_path, $relative_path );
    print STDERR "Path: $path\n";

    unless ( $fmgr->exists($path) ) {
        $fmgr->mkpath($path)
          or return $app->error(
            $app->translate(
                "Can't make path '[_1]': [_2]",
                $path, $fmgr->errstr
            )
          );
    }

    my $relative_url =
      File::Spec->catfile( $relative_path, encode_url($basename) );
    print STDERR "Relative URL: $relative_url\n";
    $relative_path =
      $relative_path
      ? File::Spec->catfile( $relative_path, $basename )
      : $basename;
    my $asset_file = $options->{'site_path'} || '%s';
    $asset_file = File::Spec->catfile( $asset_file, $relative_path );
    print STDERR "Asset file: $asset_file\n";

    my $local_file = File::Spec->catfile( $path, $basename );
    print STDERR "Local file: $local_file\n";

    my $asset_base_url = $options->{'site_path'} || '%s';

    ## Untaint. We have already tested $basename and $relative_path for security
    ## issues above, and we have to assume that we can trust the user's
    ## Local Archive Path setting. So we should be safe.
    ($local_file) = $local_file =~ /(.+)/s;

    require MT::Image;
    my ( $w, $h, $id, $write_file ) = MT::Image->check_upload(
        Fh    => $fh,
        Fmgr  => $fmgr,
        Local => $local_file
    );

    return $app->error( MT::Image->errstr )
      unless $write_file;

    ## File does not exist, or else we have confirmed that we can overwrite.
    my $umask = oct $app->config('UploadUmask');
    my $old   = umask($umask);
    defined( my $bytes = $write_file->() )
      or return $app->error(
        $app->translate(
            "Error writing upload to '[_1]': [_2]", $local_file,
            $fmgr->errstr
        )
      );
    umask($old);

    ## Close up the filehandle.
    close $fh;

    ## We are going to use $relative_path as the filename and as the url passed
    ## in to the templates. So, we want to replace all of the '\' characters
    ## with '/' characters so that it won't look like backslashed characters.
    ## Also, get rid of a slash at the front, if present.
    $relative_path =~ s!\\!/!g;
    $relative_path =~ s!^/!!;
    $relative_url  =~ s!\\!/!g;
    $relative_url  =~ s!^/!!;
    my $url = $base_url;
    $url .= '/' unless $url =~ m!/$!;
    $url .= $relative_url;
    my $asset_url = $asset_base_url . '/' . $relative_url;

    require File::Basename;
    my $local_basename = File::Basename::basename($local_file);
    my $ext =
      ( File::Basename::fileparse( $local_file, qr/[A-Za-z0-9]+$/ ) )[2];

    my $asset_pkg = MT->model('asset')->handler_for_file($local_basename);

# TODO: implement type checking
#    if (my $asset_type = $options{require_type}) {
#        require MT::Asset;
#        my $asset_pkg = MT::Asset->handler_for_file($basename);
#        if ($asset_type eq 'audio') {
#            return $app->errtrans( "Please select an audio file to upload." )
#                if !$asset_pkg->isa('MT::Asset::Audio');
#        }
#        elsif ($asset_type eq 'image') {
#            return $app->errtrans( "Please select an image to upload." )
#                if !$asset_pkg->isa('MT::Asset::Image');
#        }
#        elsif ($asset_type eq 'video') {
#            return $app->errtrans( "Please select a video to upload." )
#                if !$asset_pkg->isa('MT::Asset::Video');
#        }
#    }

    my $is_image =
         defined($w)
      && defined($h)
      && $asset_pkg->isa('MT::Asset::Image');
    my $asset;
    if (
        !(
            $asset = $asset_pkg->load(
                { file_path => $asset_file, blog_id => $blog_id }
            )
        )
      )
    {
        $asset = $asset_pkg->new();
        $asset->file_path($asset_file);
        $asset->file_name($local_basename);
        $asset->file_ext($ext);
        $asset->blog_id($blog_id);
        $asset->created_by( $app->user->id );
    }
    else {
        $asset->modified_by( $app->user->id );
    }

    my $original = $asset->clone;
    $asset->url($asset_url);
    if ($is_image) {
        $asset->image_width($w);
        $asset->image_height($h);
    }
    $asset->mime_type($mimetype) if $mimetype;
    $asset->save;
    $app->run_callbacks( 'cms_post_save.asset', $app, $asset, $original );

    if ($is_image) {
        $app->run_callbacks(
            'cms_upload_file.' . $asset->class,
            File  => $local_file,
            file  => $local_file,
            Url   => $url,
            url   => $url,
            Size  => $bytes,
            size  => $bytes,
            Asset => $asset,
            asset => $asset,
            Type  => 'image',
            type  => 'image',
            Blog  => $blog,
            blog  => $blog
        );
        $app->run_callbacks(
            'cms_upload_image',
            File       => $local_file,
            file       => $local_file,
            Url        => $url,
            url        => $url,
            Size       => $bytes,
            size       => $bytes,
            Asset      => $asset,
            asset      => $asset,
            Height     => $h,
            height     => $h,
            Width      => $w,
            width      => $w,
            Type       => 'image',
            type       => 'image',
            ImageType  => $id,
            image_type => $id,
            Blog       => $blog,
            blog       => $blog
        );
    }
    else {
        $app->run_callbacks(
            'cms_upload_file.' . $asset->class,
            File  => $local_file,
            file  => $local_file,
            Url   => $url,
            url   => $url,
            Size  => $bytes,
            size  => $bytes,
            Asset => $asset,
            asset => $asset,
            Type  => 'file',
            type  => 'file',
            Blog  => $blog,
            blog  => $blog
        );
    }

    return ( $asset, $bytes );
} ## end _upload_file

sub _ui_prefs_from_params {
    my $app  = shift;
    my $q    = $app->query;
    my %prefs;
    if (my $exp  = $q->param('collapsed')) {
        $prefs{'collapsed'} = $exp;
    }
    if (my $fav  = $q->param('favorites')) {
        $prefs{'favorites'} = $fav;
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



