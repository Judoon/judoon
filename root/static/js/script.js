/* Author: Fitz Elliott

*/

// "use strict";

var widget_count = 0;


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
        var widget_id = widget_count++;
        var widget_id_str = 'widget_id_' + widget_id;
        widget.attr('id', widget_id_str);

        var widget_format_id = 'widget_format_id_' + widget_id;
        var widget_format_target = widget.children('.widget-format-target')
            .attr('id', widget_format_id);

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
    canvas.find('select option:selected').each(function() {
        $(this).attr('selected', 1);
    });
    $('input[name="page_column.template"]').attr('value', canvas.html());
}


function translate_column_template() {
    $('#page_column.template').attr('value', 'new_template');
}
