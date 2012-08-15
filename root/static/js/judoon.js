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

        }, /* end bootstrap_init */
    },
};
