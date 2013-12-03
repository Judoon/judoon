// Avoid `console` errors in browsers that lack a console.
if (!(window.console && console.log)) {
    (function() {
        var noop = function() {};
        var methods = ['assert', 'clear', 'count', 'debug', 'dir', 'dirxml', 'error', 'exception', 'group', 'groupCollapsed', 'groupEnd', 'info', 'log', 'markTimeline', 'profile', 'profileEnd', 'markTimeline', 'table', 'time', 'timeEnd', 'timeStamp', 'trace', 'warn'];
        var length = methods.length;
        var console = window.console = {};
        while (length--) {
            console[methods[length]] = noop;
        }
    }());
}


$(document).ready(function() {

    var aoColumns = [];
    for (var i=0; i<column_data.length; i++) {
        aoColumns.push({
            sTitle : column_data[i].title,
            sName  : column_data[i].sort_fields,
            mData  : Handlebars.compile(column_data[i].template)
        });
    }

    $('#datatable').dataTable({
        "aoColumns"       : aoColumns,
        "bAutoWidth"      : false,
        "bServerSide"     : true,
        "bProcessing"     : true,
        "bDeferRender"    : true,
        "sPaginationType" : "bootstrap",
        "sAjaxSource"     : "cgi-bin/data.cgi",
        "sAjaxDataProp"   : "tmplData"
    });
});

