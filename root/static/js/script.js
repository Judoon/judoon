/* Author: Fitz Elliott

*/


function pbuild_add_text_element() {
    var canvas = $('#column_canvas');
    var cursor = $('#canvas_cursor');
    cursor.before(new_text_element());
}


function pbuild_add_data_element() {
    var canvas = $('#column_canvas');
    var cursor = $('#canvas_cursor');
    cursor.before(new_data_element());
}

function pbuild_add_link_element() {
    var canvas = $('#column_canvas');
    var cursor = $('#canvas_cursor');
    cursor.before(new_link_element());
}

function pbuild_add_newline_element() {
    var canvas = $('#column_canvas');
    var cursor = $('#canvas_cursor');
    cursor.before(new_newline_element());
}

function pbuild_add_list_element() {

}
function pbuild_add_if_element() {

}






function new_text_element()    { return $('#input_w_dropdown').html(); }
function new_data_element()    { return $('#data_field').html();       }
function new_link_element()    { return $('#link_widget').html();      }
function new_newline_element() { return $('#newline').html();          }


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
    else if (p.hasClass('widget-newline')) {
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
    else if (p.hasClass('widget-newline-icon')) {
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
    var current_line_begin = cursor.prevAll('.widget-newline').first();
    if (!current_line_begin.length) {
        return pbuild_cursor_do_nothing();
    }
    
    
    var mv_count = cursor.prevUntil('.widget-newline').length;
    var prev_line_begin = current_line_begin.prevAll('.widget-newline').first();
    if (!prev_line_begin.length) {
        prev_line_begin = cursor.siblings().first();
    }
    else {
        prev_line_begin = prev_line_begin.next();
    }

    if (prev_line_begin.hasClass('widget-newline-icon')) {
        cursor.detach().insertBefore(prev_line_begin);
        return;
    }

    var current_pos = prev_line_begin;
    while (mv_count-- > 0) {
        if (!current_pos.length || current_pos.hasClass('widget-newline-icon')) {
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
    var current_line_end = cursor.nextAll('.widget-newline-icon').first();
    if (!current_line_end.length) {
        return pbuild_cursor_do_nothing();
    }
    
    var mv_count = cursor.prevUntil('.widget-newline').length;
    var next_line_begin = current_line_end.next();
    var current_pos = next_line_begin;
    while (mv_count-- > 0) {
        if (!current_pos.next().length || current_pos.hasClass('widget-newline-icon')) {
            break;
        }
        current_pos = current_pos.next();
    }

    cursor.detach().insertAfter(current_pos);
    return;
}
function pbuild_cursor_do_nothing() { alert('cursor do nothing!'); return; }
