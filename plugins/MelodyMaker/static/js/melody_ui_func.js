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

        /* Entry/Page Screen */
        $('.entry-date').datepicker({
            'dateFormat' : 'yy-mm-dd' 
        });

        /* Blog Selector */
        $('#search-sites').ajaxForm({
            dataType:'json',
            error: function(data,msg,error) {
                alert('There was an error processing the results: ' + msg + ', error=' + error);
                var ul = $('#site_search_results').show();
            },
            beforeSubmit: function() {
                $('#site_search_results_indicator').remove();
                var ul = $('#site_search_results').fadeOut();
                $('<div id="site_search_results_indicator" class="spinner">Spinning</div>').insertAfter(ul);
            },
            success: function(data) {
                var blogs = data['result'];
                var indicator = $('#site_search_results_indicator');
                if (blogs.length == 0) {
                    indicator.attr('class','no_results').html('No blogs found.');
                } else {
                    indicator.remove();
                    var ul = $('#site_search_results').empty().show();
                    jQuery.each(blogs, function( index, blog ) { 
                        $('<li class="site result"><a href="'+ScriptURI+'?blog_id='+blog['blog.id']+'&amp;__mode=dashboard"><img src="'+StaticURI+'support/plugins/melodymaker/images/site_search/ico_default_logo.png"></a><div class="result_data"><a class="pin" href="#">Pin This Site</a><h4 class="site_title"><a href="'+ScriptURI+'?blog_id='+blog['blog.id']+'&amp;__mode=dashboard">'+blog[ 'blog.name' ]+'</a></h4><a class="site_preview" rel="external" href="'+blog['blog.site_url']+'">'+blog['blog.site_url']+'</a></div></li>').hide().appendTo( ul ).fadeIn();
                    });
                }
            }
        });

	});

})(jQuery);