jQuery(document).ready( function($) {
    var count = $('.debug-panel li').size() - 1;
    $('#console-status-widget').click( function() {
        if ( $('.debug-panel').is(':visible') ) { //hasClass('hidden') ) {
            $('.debug-panel').hide();//removeClass('hidden');
        } else {
            $('.debug-panel').show();//addClass('hidden');
        }
    });
    if (count > 0) {
        $('#console-status-widget').append(' <span>'+count+'</span>');
    }
});