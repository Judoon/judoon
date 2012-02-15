/* Author: Fitz Elliott

*/


function pbuild_add_text_element() {
    var canvas = $('#column_canvas');
    var cursor = $('#canvas_cursor');
    cursor.before(new_text_element());
}


function pbuild_add_data_element() {

}

function pbuild_add_link_element() {

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






function new_text_element() { return $('#input_w_dropdown').html(); }
function new_newline_element() { return $('#newline').html(); }
