// (c) Yegor Kaliberda, 2017 - www.kaliberda.com
jQuery(document).ready(function() {
	
	/* Active tab */
	jQuery('#transport a').click(function() {
		jQuery('#location').removeClass('active');
		jQuery('#transport').addClass('active');
		jQuery('.transport').show(300);
		jQuery('.location').hide();
		jQuery('.tabs .row').show();
		jQuery('.transport button').each(function() {
			jQuery(this).removeClass('active');
		});
		jQuery('#t-all').addClass('active');
		return false;
	});
	jQuery('#location a').click(function() {
		jQuery('#transport').removeClass('active');
		jQuery('#location').addClass('active');
		jQuery('.transport').hide();
		jQuery('.location').show(300);
		jQuery('.tabs .row').show();
		jQuery('.location button').each(function() {
			jQuery(this).removeClass('active');
		});
		jQuery('#l-all').addClass('active');
		return false;
	});
	
	
	jQuery('.transport button').click(function() {
		/* Active button */
		jQuery('.transport button').each(function() {
			jQuery(this).removeClass('active');
		});
		jQuery(this).addClass('active');
		
		/* Show | Hide */
		if(jQuery(this).attr('id') == 't-all') {
			jQuery('.tabs .row').show();
		}
		else {
			jQuery('.tabs .row').hide();
			var id = jQuery(this).attr('id');
			jQuery('.tabs .'+id).show();
		}
		return false;
	});
	
	jQuery('.location button').click(function() {
		/* Active button */
		jQuery('.location button').each(function() {
			jQuery(this).removeClass('active');
		});
		jQuery(this).addClass('active');
		
		/* Show | Hide */
		if(jQuery(this).attr('id') == 'l-all') {
			jQuery('.tabs .row').show();
		}
		else {
			jQuery('.tabs .row').hide();
			var id = jQuery(this).attr('id');
			jQuery('.tabs .'+id).show();
		}
		return false;
	});
	
	/* Show full route */
	jQuery('.showfull').click(function(e) {
		jQuery(this).parent().hide(50);
		jQuery(this).parent().next('.full').show(300);
	});
	/* Hide full route */
	jQuery('.showshort').click(function(e) {
		jQuery(this).parent().hide(50);
		jQuery(this).parent().prev('.short').show(300);
	});
	
	var headerOffset = $('.fixed-header').offset().top;

	jQuery(window).scroll(function(){
		var header = jQuery('.fixed-header');
		var clr = jQuery('.header-clr');
		scroll = jQuery(window).scrollTop();

		if (scroll >= headerOffset) {
			header.addClass('fixed');
			clr.height(header.height() + 10 + 'px');
		}
  		else {
			header.removeClass('fixed');
			clr.height('10px');
		}
	});
	
});