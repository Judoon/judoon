/*jshint globalstrict: true, jquery: true */
/*global jQuery,document,Handlebars */

'use strict';

function initDataTable(tableId, dataUrl, columnUrl, getColsFn) {
    jQuery.get(
        columnUrl,
        function (data) {
            jQuery('#datatable').dataTable({
                "aoColumns"       : getColsFn(data),
                "bAutoWidth"      : false,
                "bServerSide"     : true,
                "bProcessing"     : true,
                "bDeferRender"    : true,
                "sPaginationType" : "bootstrap",
                "sAjaxSource"     : dataUrl,
                "sAjaxDataProp"   : "tmplData"
            });
        }
    );

    return;
}

function getDatasetCols(columnData) {
    var aoColumns = [];
    for (var i=0; i<columnData.length; i++) {
        aoColumns.push({
            sTitle : Handlebars.Utils.escapeExpression(columnData[i].name),
            sName  : columnData[i].shortname,
            mData  : Handlebars.compile('{{'+columnData[i].shortname+'}}')
        });
    }
    return aoColumns;
}

function getPageCols(columnData) {
    var aoColumns = [];
    for (var i=0; i<columnData.length; i++) {
        aoColumns.push({
            sTitle : columnData[i].title,
            sName  : columnData[i].sort_fields,
            mData  : Handlebars.compile(columnData[i].template)
        });
    }
    return aoColumns;
}
