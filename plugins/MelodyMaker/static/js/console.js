jQuery(document).ready( function($) {
    var count = $('.debug-panel li').size() - 1;
    $('#console-status-widget').click( function() {
        if ( $('.debug-panel').is(':visible') ) { 
            $('.debug-panel').hide();
            $(this).removeClass('active');
        } else {
            $('.debug-panel').show();
            $(this).addClass('active');
        }
    });
    if (count > 0) {
        $('#console-status-widget').append(' <span>'+count+'</span>');
    }
});