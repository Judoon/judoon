/* Author: Fitz Elliott

*/

// "use strict";

var widget_count = 0;

/*
function pbuild_delete_before_cursor {
    var del_tgt = $("#canvas_cursor").prev().attr
    pbuild_delete_widget()
}
*/

function pbuild_delete_widget(widget_id) {
    $(widget_id).remove();
    return false;
}

function pbuild_backspace() {
    $('#canvas_cursor').prev('.widget-object').remove();
}

function pbuild_toggle_format_bold(widget_id) {
    $(widget_id).toggleClass('widget-formatting-bold');
    return false;
}

function pbuild_toggle_format_italic(widget_id) {
    $(widget_id).toggleClass('widget-formatting-italic');
    return false;
}

function pbuild_add_widget(type) {
    $("#"+type+"_widget").children().each(function() {
        var widget = $(this).clone();
        pbuild_init_widget(widget);
        $('#canvas_cursor').before(widget);
    });
}

function pbuild_cursor_do_nothing() { alert('cursor do nothing!'); return; }

function pbuild_cursor_left() {
    var canvas = $('#column_canvas');
    var cursor = $('#canvas_cursor');
    var p = cursor.prev();
    if (!p.length) {
        return pbuild_cursor_do_nothing();
    }
    else if (p.hasClass('widget-inline')) {
        cursor.detach().insertBefore(p);
    }
    else if (p.hasClass('widget-type-newline')) {
        cursor.detach().insertBefore(p.prev());
    }
    else {
        alert('Not sure how to move cursor left!');
        return pbuild_cursor_do_nothing();
    }
}
function pbuild_cursor_right() {
    var canvas = $('#column_canvas');
    var cursor = $('#canvas_cursor');
    var p = cursor.next();
    if (!p.length) {
        return pbuild_cursor_do_nothing();
    }
    else if (p.hasClass('widget-inline')) {
        cursor.detach().insertAfter(p);
    }
    else if (p.hasClass('widget-type-newline-icon')) {
        cursor.detach().insertAfter(p.next());
    }
    else {
        alert('Not sure how to move cursor right!');
        return pbuild_cursor_do_nothing();
    }
}
function pbuild_cursor_up() {
    var canvas = $('#column_canvas');
    var cursor = $('#canvas_cursor');
    var current_line_begin = cursor.prevAll('.widget-type-newline').first();
    if (!current_line_begin.length) {
        return pbuild_cursor_do_nothing();
    }
    
    
    var mv_count = cursor.prevUntil('.widget-type-newline').length;
    var prev_line_begin = current_line_begin.prevAll('.widget-type-newline').first();
    if (!prev_line_begin.length) {
        prev_line_begin = cursor.siblings().first();
    }
    else {
        prev_line_begin = prev_line_begin.next();
    }

    if (prev_line_begin.hasClass('widget-type-newline-icon')) {
        cursor.detach().insertBefore(prev_line_begin);
        return;
    }

    var current_pos = prev_line_begin;
    while (mv_count-- > 0) {
        if (!current_pos.length || current_pos.hasClass('widget-type-newline-icon')) {
            break;
        }
        current_pos = current_pos.next();
    }

    cursor.detach().insertBefore(current_pos);
    return;
}
function pbuild_cursor_down() {
    var canvas = $('#column_canvas');
    var cursor = $('#canvas_cursor');
    var current_line_end = cursor.nextAll('.widget-type-newline-icon').first();
    if (!current_line_end.length) {
        return pbuild_cursor_do_nothing();
    }
    
    var mv_count = cursor.prevUntil('.widget-type-newline').length;
    var next_line_begin = current_line_end.next();
    var current_pos = next_line_begin;
    while (mv_count-- > 0) {
        if (!current_pos.next().length || current_pos.hasClass('widget-type-newline-icon')) {
            break;
        }
        current_pos = current_pos.next();
    }

    cursor.detach().insertAfter(current_pos);
    return;
}


function pbuild_copy_canvas_to_input() {
    var canvas = $('#column_canvas');
    canvas.find('input').each(function() {
        $(this).attr('value', $(this).val());
    });
    canvas.find('select option').filter(':selected').each(function() {
        $(this).attr('selected', 1);
    });
    canvas.find('select option').not(':selected').each(function() {
        $(this).removeAttr('selected');
    });
    $('input[name="page_column.template"]').attr('value', canvas.html());
}


function translate_column_template() {
    $('#page_column.template').attr('value', 'new_template');
}


function pbuild_select_link_source() {
    var source = $('#link_source').val();
    $("#link_widget_url_source select.link_site_active").removeClass('link_site_active');
    $("#link_site_" + source).addClass('link_site_active');
    pbuild_select_link_site();
}

function pbuild_select_link_site() {
    var new_site = $("#link_widget_url_source select.link_site_active option").filter("option:selected");
    $('#link_widget_label_default_preview').html(new_site.text());
    $('#link_widget_label_url_preview').html(new_site.attr('title'));
    pbuild_link_widget_preview();
}

function pbuild_link_widget_preview() {
    var link_site = $("#link_widget_url_source select.link_site_active option").filter(":selected");
    var label_url = link_site.attr('title');

    var label_type_val = $('#link_widget_label_form input[name="link.label_type"]:checked').val();
    var label_preview = label_type_val === 'default' ? link_site.text()
                      : label_type_val === 'url'     ? label_url
                      : label_type_val === 'static'  ? $('#link_label_static').val()
                      :                                'Something went wrong!';
                     
    $('#link_widget_label_preview').html('<a href="'+label_url+'" title="'+label_url+'">'+label_preview+'</a>');
    $('#link_widget_url_preview').html(label_url);
}


function pbuild_open_link_form(link_widget_button) {
    var this_btn = link_widget_button;
    $('#linkModal').modal();
    $('#linkModal').data('widget_id', $(this_btn).parent().attr('id'));
    pbuild_link_widget_preview();
}


function pbuild_submit_link_form() {
    $('#linkModal').modal('hide');
    var widget_id = $('#linkModal').data('widget_id');
    var widget = $('#'+widget_id);

    // set link url properties
    var link_source = $('#link_source').val();
    widget.find('input[class*="widget-link-url-source"]').attr('value', link_source);
    widget.find('input[class*="widget-link-url-datafield"]').attr('value', link_source);

    var link_site = $("#link_widget_url_source select.link_site_active option").filter(":selected");
    var link_site_val = link_site.val();
    widget.find('input[class*="widget-link-url-site"]').attr('value', link_site_val);

    widget.find('input[class*="widget-link-url-prefix"]').attr('value', pbuild_links[link_site_val].prefix);
    widget.find('input[class*="widget-link-url-postfix"]').attr('value', pbuild_links[link_site_val].postfix);


    // set label properties
    var label_type_val = $('#link_widget_label_form input[name="link.label_type"]:checked').val();
    var label_type = label_type_val === 'url' ? 'url' : 'static';
    var label_value = label_type_val === 'default' ? link_site.text()
                    : label_type_val === 'url'     ? ''
                    : label_type_val === 'static'  ? $('#link_label_static').val()
                    :                                'Something went wrong!';
    widget.find('input[class*="widget-link-label-type"]').attr('value', label_type);
    widget.find('input[class*="widget-link-label-value"]').attr('value', label_value);

/*
*/
}


function pbuild_init_stored_widget(widget) {
    pbuild_init_widget(widget);
    if (widget.hasClass('widget-type-data')) {
        var select = widget.find('select');
        var selected_option =  select.find('option').filter(':selected').detach();

        for (col in ds_columns_dict) {
            select.append('<option value="'+ds_columns_dict[col]['shortname']+'">{'+ ds_columns_dict[col]['name'] + '}</option>');
            if (ds_columns_dict[col]['shortname'] === selected_option.attr('value')) {
                select.children().last().attr('selected', 1);
            }
        }
    }
}

function pbuild_init_widget(widget) {
        var widget_id = widget_count++;
        var widget_id_str = 'widget_id_' + widget_id;
        widget.attr('id', widget_id_str);

        var widget_format_id = 'widget_format_id_' + widget_id;
        var widget_format_target = widget.children('.widget-format-target')
            .attr('id', widget_format_id);
        pbuild_add_formatter(widget);
}

function pbuild_add_formatter(widget) {
    widget.find('.widget-format-sibling').first().after($('#formatting_menu').html());
    var widget_format_id = widget.children('.widget-format-target').attr('id');
    var widget_dd = widget.children('ul.dropdown-menu');
    if (widget_dd.length) {
        widget_dd.find('.widget-action-bold').on(
            'click', function() {
                pbuild_toggle_format_bold('#'+widget_format_id);
            }
        );
        widget_dd.find('.widget-action-italic').on(
            'click', function() {
                pbuild_toggle_format_italic('#'+widget_format_id);
            }
        );
        widget_dd.find('.widget-action-delete').on(
            'click', function() {
                pbuild_delete_widget('#'+widget_id_str);
            }
        );
    }
}


function judoon_dt_bootstrap_init() {

    $.extend( $.fn.dataTableExt.oStdClasses, {
    	"sWrapper": "dataTables_wrapper form-inline"
    } );

    /* API method to get paging information */
    $.fn.dataTableExt.oApi.fnPagingInfo = function ( oSettings )
    {
    	return {
    	    "iStart":         oSettings._iDisplayStart,
    	    "iEnd":           oSettings.fnDisplayEnd(),
    	    "iLength":        oSettings._iDisplayLength,
    	    "iTotal":         oSettings.fnRecordsTotal(),
    	    "iFilteredTotal": oSettings.fnRecordsDisplay(),
    	    "iPage":          Math.ceil( oSettings._iDisplayStart / oSettings._iDisplayLength ),
    	    "iTotalPages":    Math.ceil( oSettings.fnRecordsDisplay() / oSettings._iDisplayLength )
    	};
    }

    /* Bootstrap style pagination control */
    $.extend( $.fn.dataTableExt.oPagination, {
	"bootstrap": {
	    "fnInit": function( oSettings, nPaging, fnDraw ) {
		var oLang = oSettings.oLanguage.oPaginate;
		var fnClickHandler = function ( e ) {
		    e.preventDefault();
		    if ( oSettings.oApi._fnPageChange(oSettings, e.data.action) ) {
			fnDraw( oSettings );
		    }
		};

		$(nPaging).addClass('pagination').append(
		    '<ul>'+
			'<li class="prev disabled"><a href="#">&larr; '+oLang.sPrevious+'</a></li>'+
			'<li class="next disabled"><a href="#">'+oLang.sNext+' &rarr; </a></li>'+
			'</ul>'
		);
		var els = $('a', nPaging);
		$(els[0]).bind( 'click.DT', { action: "previous" }, fnClickHandler );
		$(els[1]).bind( 'click.DT', { action: "next" }, fnClickHandler );
	    },

	    "fnUpdate": function ( oSettings, fnDraw ) {
		var iListLength = 5;
		var oPaging = oSettings.oInstance.fnPagingInfo();
		var an = oSettings.aanFeatures.p;
		var i, j, sClass, iStart, iEnd, iHalf=Math.floor(iListLength/2);

		if ( oPaging.iTotalPages < iListLength) {
		    iStart = 1;
		    iEnd = oPaging.iTotalPages;
		}
		else if ( oPaging.iPage <= iHalf ) {
		    iStart = 1;
		    iEnd = iListLength;
		} else if ( oPaging.iPage >= (oPaging.iTotalPages-iHalf) ) {
		    iStart = oPaging.iTotalPages - iListLength + 1;
		    iEnd = oPaging.iTotalPages;
		} else {
		    iStart = oPaging.iPage - iHalf + 1;
		    iEnd = iStart + iListLength - 1;
		}

		for ( i=0, iLen=an.length ; i<iLen ; i++ ) {
		    // Remove the middle elements
		    $('li:gt(0)', an[i]).filter(':not(:last)').remove();

		    // Add the new list items and their event handlers
		    for ( j=iStart ; j<=iEnd ; j++ ) {
			sClass = (j==oPaging.iPage+1) ? 'class="active"' : '';
			$('<li '+sClass+'><a href="#">'+j+'</a></li>')
			    .insertBefore( $('li:last', an[i])[0] )
			    .bind('click', function (e) {
				e.preventDefault();
				oSettings._iDisplayStart = (parseInt($('a', this).text(),10)-1) * oPaging.iLength;
				fnDraw( oSettings );
			    } );
		    }

		    // Add / remove disabled classes from the static elements
		    if ( oPaging.iPage === 0 ) {
			$('li:first', an[i]).addClass('disabled');
		    } else {
			$('li:first', an[i]).removeClass('disabled');
		    }

		    if ( oPaging.iPage === oPaging.iTotalPages-1 || oPaging.iTotalPages === 0 ) {
			$('li:last', an[i]).addClass('disabled');
		    } else {
			$('li:last', an[i]).removeClass('disabled');
		    }
		}
	    }
	}
    } );

}
