package MelodyMaker::Callbacks;

use strict;
use MT::Util;

sub header_param {
    my ($cb, $app, $param, $tmpl) = @_;
    my $perms = $app->user->permissions;
    require JSON;
    my $prefs = JSON::jsonToObj( $perms->ui_prefs );
    my @collapsed = split(',',$prefs->{'collapsed'});
    my $menus = $app->registry('menus');
    foreach my $id (@collapsed) {
        $id =~ s/-menu//;
        $menus->{$id}->{collapsed} = 1;
    }
} ## end header_param 

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



