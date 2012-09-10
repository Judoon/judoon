/*
 * judoon.js - encapsulation of the judoon code library
 *
 */

/*global $:false, jQuery:false */
// "use strict";

var judoon = {
    canvas: {
        cursor: {
            get_cursor: function() { return $('#canvas_cursor'); },
            do_nothing: function() { return; },

            move_left: function() {
                var cursor = this.get_cursor();
                var p = cursor.prev();
                if (!p.length) {
                    return this.do_nothing();
                }
                else if (p.hasClass('widget-inline')) {
                    cursor.detach().insertBefore(p);
                }
                else if (p.hasClass('widget-type-newline')) {
                    cursor.detach().insertBefore(p.prev());
                }
                else {
                    return this.do_nothing();
                }

                return;
            },

            move_right: function() {
                var cursor = this.get_cursor();
                var p = cursor.next();
                if (!p.length) {
                    return this.do_nothing();
                }
                else if (p.hasClass('widget-inline')) {
                    cursor.detach().insertAfter(p);
                }
                else if (p.hasClass('widget-type-newline-icon')) {
                    cursor.detach().insertAfter(p.next());
                }
                else {
                    return this.do_nothing();
                }

                return;
            },

            move_up: function() {
                var cursor = this.get_cursor();
                var current_line_begin = cursor.prevAll('.widget-type-newline').first();
                var mv_count, prev_line_begin, current_pos;

                if (!current_line_begin.length) {
                    return this.do_nothing();
                }

                mv_count = cursor.prevUntil('.widget-type-newline').length;
                prev_line_begin = current_line_begin.prevAll('.widget-type-newline').first();
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

                current_pos = prev_line_begin;
                while (mv_count-- > 0) {
                    if (!current_pos.length || current_pos.hasClass('widget-type-newline-icon')) {
                        break;
                    }
                    current_pos = current_pos.next();
                }

                cursor.detach().insertBefore(current_pos);
                return;
            },

            move_down: function() {
                var cursor = this.get_cursor();
                var current_line_end = cursor.nextAll('.widget-type-newline-icon').first();
                var mv_count, next_line_begin, current_pos;

                if (!current_line_end.length) {
                    return this.do_nothing();
                }

                mv_count = cursor.prevUntil('.widget-type-newline').length;
                next_line_begin = current_line_end.next();
                current_pos = next_line_begin;
                while (mv_count-- > 0) {
                    if (!current_pos.next().length || current_pos.hasClass('widget-type-newline-icon')) {
                        break;
                    }
                    current_pos = current_pos.next();
                }

                cursor.detach().insertAfter(current_pos);
                return;
            },

            backspace: function () {
                this.get_cursor().prev('.widget-object').remove();
            }

        }, /* end canvas.cursor */


        get_canvas: function() { return $('#column_canvas'); },

        serialize: function() {
            var judoon_canvas = this;
            var new_template = [];
            judoon_canvas.get_canvas().find('div.widget-object').each(function(idx) {
                var widget_classes = $(this).attr('class');
                var widget_match   = /widget-type-([\w\-]+)/.exec(widget_classes);
                var widget_type    = widget_match[1];
                var node = {};
                switch (widget_type) {
                    case 'newline':
                        node.type = 'newline';
                        break;
                    case 'newline-icon':
                        node.type = null;
                        break;
                    case 'text':
                        node.type = 'text';
                        node.value = $(this).find('input').val();
                        node.formatting = judoon_canvas.widget.extract_format($(this));
                        break;
                    case 'data':
                        node.type = 'variable';
                        node.name = $(this).find('select').val();
                        node.formatting = judoon_canvas.widget.extract_format($(this));
                        break;
                    case 'link':
                        node.type  = 'link';
                        node.url   = judoon_canvas.widget.get_link_attr($(this), 'url');
                        node.label = judoon_canvas.widget.get_link_attr($(this), 'label');
                        node.formatting = judoon_canvas.widget.extract_format($(this));
                        break;
                }

                if (node.type !== null) {
                    new_template.push(node);
                }
            });
            return $.toJSON(new_template);
        },

        save_to_input: function() {
            $('input[name="page_column.template"]').attr('value', judoon.canvas.serialize());
        },

        build_widgets: function(widgets_spec) {
            for (var i in widgets_spec) {
                var widget = widgets_spec[i];
                var widget_type = widget.type === 'variable' ? 'data' : widget.type;
                judoon.canvas.widget.add(widget_type);
                var new_widget = judoon.canvas.cursor.get_cursor().prev();

                switch (widget.type) {
                    case 'text':
                        new_widget.find('input').val(widget.value);
                        break;
                    case 'variable':
                        new_widget.find('select').val(widget.name);
                        break;
                    case 'link':
                        judoon.linkbuilder.set_attrs(new_widget, 'url', {
                            "type":                 widget.url.varstring_type,
                            "accession":            widget.url.accession,
                            "text-segment-1":       widget.url.text_segments[0],
                            "text-segment-2":       widget.url.text_segments[1],
                            "variable-segment-1":   widget.url.variable_segments[0]
                        });
                        judoon.linkbuilder.set_attrs(new_widget, 'label', {
                            "type":                 widget.label.varstring_type,
                            "accession":            widget.label.accession,
                            "text-segment-1":       widget.label.text_segments[0],
                            "text-segment-2":       widget.label.text_segments[1],
                            "variable-segment-1":   widget.label.variable_segments[0]
                        });
                        break;
                    default:
                        break;
                }

                if (widget.formatting) {
                   for (var j in widget.formatting) {
                       var format = widget.formatting[j];
                       if (format === 'bold') {
                           judoon.canvas.widget.toggle_bold(new_widget);
                       }
                       else if (format === 'italic') {
                           judoon.canvas.widget.toggle_italic(new_widget);
                       }
                   }
                }
            }
        },

        widget: {
            count: 0,

            add: function(type) {
                var judoon_widget = this;
                $("#"+type+"_widget").children().each(function() {
                    var widget = $(this).clone();
                    var widget_id = judoon_widget.count++;
                    widget.attr('id', 'widget_id_' + widget_id);
                    judoon_widget.add_formatter(widget);
                    $('#canvas_cursor').before(widget);
                });
            },

            remove: function(widget) { 
                widget.remove();
            },

            add_formatter: function(widget) {
                var format_target = widget.find('.widget-format-target');
                format_target.first().after($('#formatting_menu').html());
                var widget_dd = widget.children('ul.dropdown-menu');
                if (widget_dd.length) {
                    widget_dd.find('.widget-action-bold').on(
                        'click', function() {
                            judoon.canvas.widget.toggle_bold(widget);
                        }
                    );
                    widget_dd.find('.widget-action-italic').on(
                        'click', function() {
                            judoon.canvas.widget.toggle_italic(widget);
                        }
                    );
                    widget_dd.find('.widget-action-delete').on(
                        'click', function() {
                            judoon.canvas.widget.remove(widget);
                        }
                    );
                }

            },

            toggle_bold: function(widget) {
                var format_target = widget.find('.widget-format-target');
                format_target.toggleClass('widget-formatting-bold');
            },

            toggle_italic: function(widget) {
                var format_target = widget.find('.widget-format-target');
                format_target.toggleClass('widget-formatting-italic');
            },

            extract_format: function(widget) {
                var format_class = widget.find('.widget-format-target').attr('class');
                var formats = [];
                var format_matches;
                var format_re = /widget-formatting-([\w\-]+)/g;
                while ((format_matches = format_re.exec(format_class)) !== null) {
                    formats.push(format_matches[1]);
                }
                return formats;
            },

            get_link_attr: function(widget, attr) {
                var attrs = judoon.linkbuilder.get_attrs(widget, attr);
                var varstring = {
                    varstring_type:    attrs.type,
                    accession:         attrs.accession,
                    text_segments:     [attrs["text-segment-1"], attrs["text-segment-2"]],
                    variable_segments: [attrs["variable-segment-1"]]
                };
                return varstring;
            }
        } /* end canvas.widget */

    }, /* end canvas */


    /***
     *
     * Link Builder Modal functions
     *
     ***/
    linkbuilder: {

        // open and initialize the link modal
        open: function(link_widget_button) {
            var this_btn = link_widget_button;
            var widget   = $(this_btn).parent();
            $('#linkModal').data('widget_id', widget.attr('id'));

            var props = {
                url:   this.get_attrs(widget, 'url'),
                label: this.get_attrs(widget, 'label')
            };

            // initialize url form values
            var default_label = 'Link';
            var url_radio = this.url.get_type();
            if (props.url.type === 'accession') {
                url_radio.val(['accession']);
                this.url.accession.set_source(props.url['variable-segment-1']);
                this.url.accession.set_site(props.url.accession);
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
            var label_radio = this.label.get_type();
            if (props.label.type === "accession") {
                label_radio.val(['url']);
            }
            else if (props.label.type === "variable") {
                label_radio.val(['variable']);
                this.label.dynamic.get_source().val(props.label['variable-segment-1']);
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

            this.preview.update();

            // show the modal
            $('#linkModal').modal();
        },

        // Runs when user clicks 'submit' on the link modal.
        // Responsible for reading the modal forms and writing
        // out the appropriate html into the canvas
        submit: function() {
            $('#linkModal').modal('hide');
            var widget_id = $('#linkModal').data('widget_id');
            var widget    = $('#'+widget_id);

            // set link url properties
            var url_attrs = {};
            var url_type  = this.url.get_type().filter(':checked').val();
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
                var link_source_val             = this.url.accession.get_source().val();
                var link_site_val               = this.url.accession.get_site().val();
                var acc_type                    = column_acctype[link_source_val];
                url_attrs.type                  = 'accession';
                url_attrs.accession             = link_site_val;
                url_attrs['text-segment-1']     = pbuild_links[link_site_val][acc_type].prefix;
                url_attrs['text-segment-2']     = pbuild_links[link_site_val][acc_type].postfix;
                url_attrs['variable-segment-1'] = link_source_val;
            }
            else {
                throw {
                    name : 'InvalidFieldError',
                    message : url_type + ' is not a supported url_type'
                };
            }
            this.set_attrs(widget, 'url', url_attrs);

            // set label properties
            var label_type = this.label.get_type().filter(':checked').val();
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
            this.set_attrs(widget, 'label', label_attrs);
    
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
        },

        // for a given link widget, fetch the attributes for the given type
        // and stick them in a data struct
        get_attrs: function(widget, type) {
            var attrs = {};
            for (var i in this.attr_dict) {
                var attr_name = this.attr_dict[i];
                var data_key = 'widget-link-' + type + '-' + attr_name;
                attrs[attr_name] = widget.data(data_key);
            }
            return attrs;
        },

        // save the given attributes to the widget's datastore
        set_attrs: function(widget, type, attrs) {
            var data_key;
            for (var i in this.attr_dict) {
                data_key = 'widget-link-' + type + '-' + this.attr_dict[i];
                widget.data(data_key, '');
            }

            // amend or append all attributes
            for (var key in attrs) {
                data_key = 'widget-link-' + type + '-' + key;
                widget.data(data_key, attrs[key]);
            }
        },
        attr_dict: ['type', 'accession', 'text-segment-1', 'text-segment-2', 'variable-segment-1'],
        util: {

            // zip a text list and variable list into a string
            // the text list always goes first
            zip_segments: function(text_segs, data_segs) {
                var maxlen = Math.max(text_segs.length, data_segs.length);
                var retstring = '';
                for (var i = 0; i < maxlen; i++) {
                    retstring += text_segs[i] || '';
                    retstring += data_segs[i] || '';
                }
                return retstring;
            }
        },
        preview: {

            // update the link preview panel
            update: function() {
                this.update_url();
                this.update_label();
            },

            // This shouldn't be called directly, since a change in url
            // could require a change in label. Use this.update() instead.
            update_url: function() {
                var preview_url   = '';
                var url_type_val = judoon.linkbuilder.url.get_type().filter(':checked').val();
                switch (url_type_val) {
                    case 'static':
                        preview_url = $('#link_widget_url_static').val();
                        break;
                    case 'variable_simple':
                        preview_url = url_prefixes[$('#link_url_source').val()] +
                                      sample_data[$('#link_url_source').val()];
                        break;
                    case 'variable_complex':
                        var var_sample = sample_data[$('#constructed_url_source').val()];
                        var var_prefix = $('#constructed_url_prefix').val();
                        var var_suffix = $('#constructed_url_suffix').val();
                        preview_url    = judoon.linkbuilder.util.zip_segments([var_prefix, var_suffix],[var_sample]);
                        break;
                    case 'accession':
                        var site_id    = judoon.linkbuilder.url.accession.get_site().val();
                        var accession  = column_acctype[judoon.linkbuilder.url.accession.get_source().val()];
                        var link       = pbuild_links[site_id][accession];
                        var acc_sample = sitelinker_accs[accession].example;
                        preview_url    = judoon.linkbuilder.util.zip_segments([link.prefix, link.postfix], [acc_sample]);
                        break;
                    default:
                        preview_url = 'Something went wrong!';
                }

                $('#link_widget_url_preview').html(preview_url);
            },

            update_label: function() {
                var preview_url = $('#link_widget_url_preview').html();
                var preview_label = '';
                var label_type_val = judoon.linkbuilder.label.get_type().filter(':checked').val();
                switch (label_type_val) {
                    case 'default':
                        preview_label = judoon.linkbuilder.url.get_type().filter(':checked').val() === 'accession' ?
                            sitelinker_sites[judoon.linkbuilder.url.accession.get_site().val()].label
                          : 'Link';
                        break;
                    case 'url':
                        preview_label = preview_url;
                        break;
                    case 'variable':
                        var lbl_sample = sample_data[judoon.linkbuilder.label.dynamic.get_source().val()];
                        var lbl_prefix = $('#label_source_prefix').val();
                        var lbl_suffix = $('#label_source_suffix').val();
                        preview_label  = judoon.linkbuilder.util.zip_segments([lbl_prefix, lbl_suffix],[lbl_sample]);
                        break;
                    case 'static':
                        preview_label = $('#link_label_static').val();
                        break;
                    default:
                        preview_label = 'Something went wrong!';
                }

                $('#link_widget_label_preview').html('<a href="'+preview_url+'" title="'+preview_url+'">'+preview_label+'</a>');
            }
        },
        url: {
            get_type: function() {
                return $('input[name="url_type"]');
            },
            accession: {
                // get+set the accession column source dropdown
                get_source: function() { return $('#link_source'); },
                set_source: function(source_key) {
                    this.get_source().val(source_key);
                    this.set_active_sitelist();
                },

                // get+set the sitelist (changes depending on which source
                // is selected)
                get_active_sitelist: function() {
                    return $("#link_widget_url_source select.link_site_active");
                },
                set_active_sitelist: function() {
                    this.get_active_sitelist().removeClass('link_site_active');
                    $("#link_site_" + this.get_source().val()).addClass('link_site_active');
                },

                // get+set the site to be linked to
                get_site: function() {
                    return this.get_active_sitelist().children("option:selected");
                },
                set_site: function(accession) {
                    this.get_active_sitelist().val(accession);
                }
            }
        },
        label: {
            get_type: function() {
                return $('#link_widget_label_form input[name="label_type"]');
            },

            dynamic: {
                // get the dropdown to use dataset columns as labels
                get_source: function() { return $('#label_source'); }
            }

        }


    }, /* end linkbuilder */


    /***
     *
     * JQuery Datatables - bootstrap integration
     *
     ***/
    datatables: {
        bootstrap_init: function() {

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
                        var i, j, sClass, iStart, iEnd, iLen, iHalf=Math.floor(iListLength/2);

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

                        var paging_click_event = function (e) {
                            e.preventDefault();
                            oSettings._iDisplayStart = (parseInt($('a', this).text(),10)-1) * oPaging.iLength;
                            fnDraw( oSettings );
                        };
                        for ( i=0, iLen=an.length ; i<iLen ; i++ ) {
                            // Remove the middle elements
                            $('li:gt(0)', an[i]).filter(':not(:last)').remove();

                            // Add the new list items and their event handlers
                            for ( j=iStart ; j<=iEnd ; j++ ) {
                                sClass = (j==oPaging.iPage+1) ? 'class="active"' : '';
                                $('<li '+sClass+'><a href="#">'+j+'</a></li>')
                                    .insertBefore( $('li:last', an[i])[0] )
                                    .bind('click', paging_click_event);
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

        } /* end bootstrap_init */
    }
};
