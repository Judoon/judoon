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


/* ========================================

   Link Builder Modal functions

   ======================================== */

function pbuild_get_url_type() {
    return $('input[name="url_type"]');
}

function pbuild_get_active_link_site() {
    return $("#link_widget_url_source select.link_site_active");
}

function pbuild_get_selected_link_site() {
    return pbuild_get_active_link_site().children("option:selected");
}

function pbuild_set_link_source(source_key) {
    $('#link_source').val(source_key);
    pbuild_update_link_sites();
}

function pbuild_update_link_sites() {
    pbuild_get_active_link_site().removeClass('link_site_active');
    $("#link_site_" + $('#link_source').val()).addClass('link_site_active');
}

function pbuild_get_label_type() {
    return $('#link_widget_label_form input[name="label_type"]');
}

// get the dropdown to use dataset columns as labels
function pbuild_get_label_source() { return $('#label_source'); }

// zip a text list and variable list into a string
// the text list always goes first
function pbuild_zip_segments(text_segs, data_segs) {
    var maxlen = Math.max(text_segs.length, data_segs.length);
    var retstring = '';
    for (var i = 0; i < maxlen; i++) {
        retstring += text_segs[i] || '';
        retstring += data_segs[i] || '';
    }
    return retstring;
}

// update the link preview panel
function pbuild_update_preview() {
    pbuild_update_url_preview();
    pbuild_update_label_preview();
}

// this shouldn't be called directly, since a change in url could require
// a change in label. Use pbuild_update_preview() instead.
function pbuild_update_url_preview() {
    var preview_url   = '';
    var url_type_val = pbuild_get_url_type().filter(':checked').val();
    switch (url_type_val) {
        case 'static':
            preview_url = $('#link_widget_url_static').val();
            break;
        case 'variable_simple':
            preview_url = url_prefixes[$('#link_url_source').val()]
                        + sample_data[$('#link_url_source').val()];
            break;
        case 'variable_complex':
            var var_sample = sample_data[$('#constructed_url_source').val()];
            var var_prefix = $('#constructed_url_prefix').val();
            var var_suffix = $('#constructed_url_suffix').val();
            preview_url = pbuild_zip_segments([var_prefix, var_suffix],[var_sample]);
            break;
        case 'accession':
            var site_id    = pbuild_get_selected_link_site().val();
            var accession  = column_acctype[$('#link_source').val()];
            var link       = pbuild_links[site_id][accession];
            var acc_sample = sitelinker_accs[accession].example;
            preview_url    = pbuild_zip_segments([link.prefix, link.postfix], [acc_sample]);
            break;
        default:
            preview_url = 'Something went wrong!';
    }

    $('#link_widget_url_preview').html(preview_url);
}

function pbuild_update_label_preview() {
    var preview_url = $('#link_widget_url_preview').html();
    var preview_label = '';
    var label_type_val = pbuild_get_label_type().filter(':checked').val();
    switch (label_type_val) {
        case 'default':
            preview_label = pbuild_get_url_type().filter(':checked').val() === 'accession' ?
                sitelinker_sites[pbuild_get_selected_link_site().val()].label
              : 'Link';
            break;
        case 'url':
            preview_label = preview_url;
            break;
        case 'variable':
            var lbl_sample = sample_data[pbuild_get_label_source().val()];
            var lbl_prefix = $('#label_source_prefix').val();
            var lbl_suffix = $('#label_source_suffix').val();
            preview_label = pbuild_zip_segments([lbl_prefix, lbl_suffix],[lbl_sample]);
            break;
        case 'static':
            preview_label = $('#link_label_static').val();
            break;
        default:
            preview_label = 'Something went wrong!';
    }

    $('#link_widget_label_preview').html('<a href="'+preview_url+'" title="'+preview_url+'">'+preview_label+'</a>');
}


// open and initialize the link modal
function pbuild_open_link_form(link_widget_button) {
    var this_btn = link_widget_button;
    var widget   = $(this_btn).parent();
    $('#linkModal').data('widget_id', widget.attr('id'));

    var props = pbuild_get_link_props_for_widget(widget);

    // initialize url form values
    var default_label = 'Link';
    var url_radio = pbuild_get_url_type();
    if (props.url.type === 'accession') {
        url_radio.val(['accession']);
        pbuild_set_link_source(props.url['variable-segment-1']);
        pbuild_get_active_link_site().val(props.url.accession);
        default_label = sitelinker_sites[props.url.accession].label;
    }
    else if (props.url.type === 'variable') {
        var not_empty = /\S/;
        if (not_empty.test(props.url['text-segment-1'])) {
            url_radio.val(['variable_complex']);
            $('#constructed_url_source').val(props.url['variable-segment-1']);
            $('#constructed_url_prefix').val(props.url['text-segment-1']);
            $('#constructed_url_suffix').val(props.url['text-segment-2']);
        }
        else {
            url_radio.val(['variable_simple']);
            $('#link_url_source').val(props.url['variable-segment-1']);
        }
    }
    else if (props.url.type === 'static') {
        url_radio.val(['static']);
        $('#link_widget_url_static').val(props.url['text-segment-1']);
    }
    else {
        // do what?
        // do nothing.
    }

    // initialize label form values
    var label_radio = pbuild_get_label_type();
    if (props.label.type === "accession") {
        label_radio.val(['url']);
    }
    else if (props.label.type === "variable") {
        label_radio.val(['variable']);
        pbuild_get_label_source().val(props.label['variable-segment-1']);
        $('#label_source_prefix').val(props.label['text-segment-1']);
        $('#label_source_suffix').val(props.label['text-segment-2']);
    }
    else if (props.label.type === "static") {
        if (props.label['text-segment-1'] === default_label) {
            label_radio.val(['default']);
        }
        else {
            label_radio.val(['static']);
            $('#link_label_static').val(props.label['text-segment-1']);
        }
    }
    else {
        // do what?
        // do nothing.
    }

    pbuild_update_preview();

    // show the modal
    $('#linkModal').modal();
}

// Runs when user clicks 'submit' on the link modal.
// Responsible for reading the modal forms and writing
// out the appropriate html into the canvas
function pbuild_submit_link_form() {
    $('#linkModal').modal('hide');
    var widget_id = $('#linkModal').data('widget_id');
    var widget    = $('#'+widget_id);

    // set link url properties
    var url_attrs = {};
    var url_type  = pbuild_get_url_type().filter(':checked').val();
    if (url_type === 'static') {
        url_attrs.type = 'static';
        url_attrs['text-segment-1'] = $('#link_widget_url_static').val();
    }
    else if (url_type === 'variable_simple') {
        url_attrs.type = 'variable';
        url_attrs['text-segment-1']     = url_prefixes[$('#link_url_source').val()];
        url_attrs['variable-segment-1'] = $('#link_url_source').val();
    }
    else if (url_type === 'variable_complex') {
        url_attrs.type = 'variable';
        url_attrs['variable-segment-1'] = $('#constructed_url_source').val();
        url_attrs['text-segment-1']     = $('#constructed_url_prefix').val();
        url_attrs['text-segment-2']     = $('#constructed_url_suffix').val();
    }
    else if (url_type === 'accession') {
        url_attrs.type = 'accession';
        var link_source_val = $('#link_source').val();
        var link_site_val   = pbuild_get_selected_link_site().val();
        pbuild_set_link_attrs(url_attrs, link_source_val, link_site_val);
    }
    else {
        throw {
            name : 'InvalidFieldError',
            message : url_type + ' is not a supported url_type'
        };
    }
    pbuild_write_attrs(widget, url_attrs, 'url');


    // set label properties
    var label_type = pbuild_get_label_type().filter(':checked').val();
    var label_attrs = {};
    if (label_type === 'default') {
        if (url_attrs.type === 'static' || url_attrs.type === 'variable') {
            label_attrs.type = 'static';
            label_attrs['text-segment-1'] = 'Link';
        }
        else {
            label_attrs.type = 'static';
            label_attrs['text-segment-1'] = sitelinker_sites[url_attrs.accession].label;
        }
    }
    else if (label_type === 'url') {
        label_attrs = url_attrs;
    }
    else if (label_type === 'static') {
        label_attrs['text-segment-1'] = $('#link_label_static').val();
        label_attrs.type = 'static';
    }
    else if (label_type === 'variable') {
        label_attrs['text-segment-1']     = $('#label_source_prefix').val();
        label_attrs['variable-segment-1'] = $('#label_source').val();
        label_attrs['text-segment-2']     = $('#label_source_suffix').val();
        label_attrs.type = 'variable';
    }
    else {
        throw {
            name : 'InvalidFieldError',
            message : label_type + ' is not a supported label type'
        };
    }
    pbuild_write_attrs(widget, label_attrs, 'label');
    

    // Update canvas display
    var display_label = $('#link_widget_label_preview').text();
    var display_url   = $('#link_widget_url_preview').text();
    var link_display  = "Link to: ";
    if (display_label === display_url) {
        link_display += display_url;
    }
    else {
        link_display += display_label + ' (' + display_url + ')';
    }
    widget.find('.btn-edit-link').first().attr('placeholder',link_display);

}

// for a given link widget, fetch the url and label props
// and stick them in a data struct
function pbuild_get_link_props_for_widget(widget) {
    var props = {};
    var components = ['url', 'label'];
    for (var i in components) {
        props[components[i]] = {};
        var class_string = 'widget-link-' + components[i] + '-';
        widget.find('input[class^="'+class_string+'"]').each(function() {
            var prop_type = $(this).attr('class').replace(class_string, '');
            props[components[i]][prop_type] = $(this).val();
        });
    }
    return props;
}

// for urls & labels of type 'accession', lookup the segment properties
// in the property dictionaries
function pbuild_set_link_attrs(attrs, link_source, link_site, url_type) {
    attrs.accession = link_site;
    var acc_type = column_acctype[link_source];
    attrs['text-segment-1'] = pbuild_links[link_site][acc_type].prefix;
    attrs['text-segment-2'] = pbuild_links[link_site][acc_type].postfix;
    attrs['variable-segment-1'] = link_source;
}

// write the url & label attributes to the canvas as hidden inputs
function pbuild_write_attrs(widget, attrs, type) {

    // clear previous entries
    widget.find('input[class^="widget-link-'+type+'-"]').each(function() { $(this).val(""); });

    // amend or append all attributes
    for (var key in attrs) {
        var attr_input = widget.find('input.widget-link-'+type+'-'+key);
        if (attr_input.length) {
            attr_input.val(attrs[key]);
        }
        else {
            widget.append('<input type="hidden" class="widget-link-' + type + '-' + key + '" value="' + attrs[key] + '">');
        }
    }
}

function pbuild_init_stored_widget(widget) {
    pbuild_init_widget(widget);
    if (widget.hasClass('widget-type-data')) {
        var select = widget.find('select');
        var selected_option =  select.find('option').filter(':selected').detach();

        var col;
        for (col in ds_columns_dict) {
            select.append('<option value="'+ds_columns_dict[col].shortname+'">{'+ ds_columns_dict[col].name + '}</option>');
            if (ds_columns_dict[col].shortname === selected_option.attr('value')) {
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


// code taken from:
//    http://stackoverflow.com/questions/1539367/remove-whitespace-and-line-breaks-between-html-elements-using-jquery
jQuery.fn.cleanWhitespace = function() {
    textNodes = this.contents().filter(
        function() { return (this.nodeType == 3 && !/\S/.test(this.nodeValue)); })
        .remove();
    return this;
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
                pbuild_delete_widget('#'+widget.attr('id'));
            }
        );
    }
    widget.cleanWhitespace();
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
    };

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
