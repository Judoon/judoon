/*
 * judoon.js - encapsulation of the judoon code library
 *
 */

var judoon = {
    widget_count: 0,

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
                    alert('Not sure how to move cursor right!');
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
            },

        }, /* end canvas.cursor */

    },

};
