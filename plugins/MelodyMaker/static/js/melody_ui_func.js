(function($){

	var log = function(v){ // graceful logging, if console exists
	
		if(console && v){
			if(console.log)
				console.log(v);
		}
		
	}

	//stick the footer at the bottom of the page if we're on an iPad/iPhone due to viewport/page bugs in mobile webkit
	if(navigator.platform == 'iPad' || navigator.platform == 'iPhone' || navigator.platform == 'iPod')
	{
	     $("#footer").css("position", "static");
	};

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
                    // ignore silently - error can occur if person leaves page prior to
                    // ajax call returning. 
                } else {
                    // do nothing
                }
            },'json');
		});
		
		/*$('#edit-entry #admin-content-inner').wrapInner('<div id="edit-entry-box" class="widget"/>');
		$('#edit-entry #admin-content-inner').append($('#edit-entry #related-content'));*/

        /* Entry/Page Screen */
        //$('.entry-date').datepicker({
        //    'dateFormat' : 'yy-mm-dd' 
        //});

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
                        var logo = StaticURI+'support/plugins/melodymaker/images/site_search/ico_default_logo.png';
                        if ( typeof blog['blog.logo_url'] != 'undefined' ) logo = blog['blog.logo_url'];
                        $('<li id="blog-'+blog['blog.id']+'" class="site result"><a href="'+ScriptURI+'?blog_id='+blog['blog.id']+'&amp;__mode=dashboard"><img src="'+logo+'" width="38" height="38" /></a><div class="result_data"><a class="pin" href="#">Pin This Site</a><h4 class="site_title"><a href="'+ScriptURI+'?blog_id='+blog['blog.id']+'&amp;__mode=dashboard">'+blog[ 'blog.name' ]+'</a></h4><a class="site_preview" rel="external" href="'+blog['blog.site_url']+'">'+blog['blog.site_url']+'</a></div></li>').hide().appendTo( ul ).fadeIn();
                    });
                }
            }
        });

        /* Drag and Dropable Blog Favorites */
        // TODO - encapsulate into a dedicated jquery plugin file to remove global variables
        var size_limit = 5;
        var sortableIn = 0;
        $( '#pinned_sites_list' ).sortable({
            update: function(event, ui) {
                var favorites = $(this).sortable('toArray').toString().replace(/blog-/g,'');
		        $.post( ScriptURI, {
                    '__mode'      : 'save_ui_prefs',
                    'magic_token' : MagicToken,
                    'favorites'   : favorites
                }, function(data, status, xhr) {
                    if (typeof data['error'] != 'undefined') {
                        // ignore silently - error can occur if person leaves page prior to
                        // ajax call returning. 
                    } else {
                        // do nothing
                    }
                },'json');
            },
            over: function(event, ui) {
                if ( $(this).hasClass('full') ) {
                    $(this).find('.blog-highlight').height(0);
                } else {
                    $(this).find('.blog-highlight').height(67);
                }
                sortableIn = 1;
            },
            create: function(event, ui) {
                if ( $('#pinned_sites_list li').size() > (size_limit) ) {
                    $('#pinned_sites_list').addClass('full');
                }               
            },
            receive: function(event, ui) {
                if ( $('#pinned_sites_list li').size() > size_limit + 1 ) {
                    $(ui.sender).sortable('cancel');
                    $('#pinned_sites_list #drop-indicator').fadeOut('slow', function() { $(this).remove(); });
                }
                sortableIn = 1;
            },
            out: function(e, ui) { 
                sortableIn = 0; 
            },
            beforeStop: function(e, ui) {
                if (sortableIn == 0) { 
                    // TODO - this flickrs a bit, item snaps back to origination
                    ui.item.fadeOut('fast',function() { 
                        $(this).remove(); 
                        var favorites = $('#pinned_sites_list').sortable('toArray').toString().replace(/blog-/g,'');
                        if ( favorites == '' ) {
                            favorites = 'none';
                            $('#pinned_sites_list').append('<li id="drop-indicator" class="site result">Add a favorite by dropping a site here.</li>');
                        }
		                $.post( ScriptURI, {
                            '__mode'      : 'save_ui_prefs',
                            'magic_token' : MagicToken,
                            'favorites'   : favorites
                        }, function(data, status, xhr) {
                            if (typeof data['error'] != 'undefined') {
                                // ignore silently - error can occur if person leaves page prior to
                                // ajax call returning. 
                            } else {
                                // do nothing
                            }
                        },'json');
                    });
                }
            }
        });
        $( '#site_search_results' ).sortable({
            placeholder: "blog-highlight",
            connectWith: "#pinned_sites_list",
            start: function( event, ui ) {
                $(this).addClass('sorting');
                if ( $('#pinned_sites_list li').size() > (size_limit - 1) ) {
                    $('#pinned_sites_list').addClass('full');
                    $('<li id="drop-indicator" class="site result">No room at the Inn</li>').hide().appendTo('#pinned_sites_list').height( 302 ).fadeIn();
                }
            },
            deactivate: function( event, ui ) {
                $(this).removeClass('sorting');
                if ( $('#pinned_sites_list').hasClass('full') ) {
                } else {
                    $('#pinned_sites_list #drop-indicator').remove();
                }
                $('#pinned_sites_list').sortable('enable');
            }
        }).disableSelection();

	});

})(jQuery);
