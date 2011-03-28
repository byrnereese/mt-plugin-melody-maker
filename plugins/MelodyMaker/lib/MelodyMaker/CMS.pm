package MelodyMaker::CMS;

use strict;

sub _ui_prefs_from_params {
    my $app  = shift;
    my $q    = $app->query;
    my $exp  = $q->param('collapsed');
    my %prefs;
    $prefs{'collapsed'} = $exp;
    MT::Util::to_json( \%prefs );
} ## end sub _ui_prefs_from_params

sub _send_json_response {
    my ( $app, $result ) = @_;
    require JSON;
    my $json = JSON::objToJson($result);
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
    my $prefs = _ui_prefs_from_params($app);
    $perms->ui_prefs($prefs);
    $perms->save
        or return _send_json_reponse( $app, { 'error' => $app->translate( "Saving permissions failed: [_1]", $perms->errstr ) });
    return _send_json_response( $app, { 'success' => 1, 'foo' => 'bar' });
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



