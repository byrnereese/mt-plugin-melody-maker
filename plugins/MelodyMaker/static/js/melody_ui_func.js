(function($){

	var log = function(v){ // graceful logging, if console exists
	
		if(console && v){
			if(console.log)
				console.log(v);
		}
		
	}

	var setAdminHeight = function(){ // sets the height of the admin panel so it stretches to fit the window vertically
	
		headerHeight = $("header").height();
		windowHeight = $(window).height();
		
		adminHeight = windowHeight-headerHeight-52;
					
		$("#admin-blog-menu").animate({ height: adminHeight },100);
	
	}

	$(document).ready(function(e){ // fire this stuff on document ready
	
		setAdminHeight();
			
		$("#header-search-label,#search-sites label").inFieldLabels();
		
		$("#control-ui-sidebar").live("click",function(e){
			
			e.preventDefault();
			
			$("#admin-blog-menu,#control-ui-sidebar a").toggleClass('closed');
				
		});
		
		$(window).resize(setAdminHeight);
		
		$("#find-site").live("click",function(e){
			
			e.preventDefault();
			
			$(this).toggleClass("selected");
			$("#find-site-search").slideToggle(50);
			
		});
		
		$(".menu_collapse_ui").live("click",function(e){
			e.preventDefault();
			$(this).parents('.box-menu').toggleClass('collapse');
			$(this).parents('.box-menu').find('ul').slideToggle(50);
			setAdminHeight();
            var collapsed_str = '';
            $(this).parents('ul').find('.collapse').each( function() {
                if (collapsed_str != '') collapsed_str += ','
                collapsed_str += $(this).attr('id');
            });
		    $.post( ScriptURI, {
                '__mode'      : 'save_ui_prefs',
                'magic_token' : MagicToken,
                'collapsed'   : collapsed_str
            }, function(data, status, xhr) {
                if (typeof data['error'] != 'undefined') {
                    alert("There was an error saving your UI prefs: "+data['error']);
                } else {
                    // do nothing
                }
            },'json').error(function() { alert("Error saving UI prefs."); });
		});
		
		/*$('#edit-entry #admin-content-inner').wrapInner('<div id="edit-entry-box" class="widget"/>');
		$('#edit-entry #admin-content-inner').append($('#edit-entry #related-content'));*/

        $('.open-dialog').fancybox({
            'width'         : 660,
            'height'        : 498,
            'autoScale'     : false,
            'transitionIn'  : 'none',
            'transitionOut' : 'none',
            'type'          : 'iframe'
        });

	});

})(jQuery);