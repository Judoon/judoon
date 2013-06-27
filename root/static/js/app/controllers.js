'use strict';

/* Controllers */

function PageCtrl($scope, $routeParams, Page) {

    $scope.editmode = 0;

    $scope.pageId = $routeParams.pageId;
    $scope.pageLoaded = 0;
    $scope.page = Page.get({id: $scope.pageId}, function (page) {
        compile_templates(page.columns);
        $scope.pageLoaded = 1;
    });

    $scope.pageDirty = 0;
    $scope.$watch('page', function () {
        if ($scope.pageLoaded) {
            $scope.pageDirty = 1;
        }
    }, true);

    $scope.updatePage = function(){
        Page.update({
            id:         $scope.pageId,
            title:      $scope.page.title,
            preamble:   $scope.page.preamble,
            postamble:  $scope.page.postamble,
            dataset_id: $scope.page.dataset_id,
        });
    };

    var emptyTemplate = Handlebars.compile('');
    $scope._addColumn = function(columnTitle) {
        var newColumn = {title: columnTitle, template: '', compiled: emptyTemplate};
        $scope.page.columns.push(newColumn);
        return newColumn;
    };

    $scope.$watch('page.columns', function() {
        compile_templates($scope.page.columns);
    }, true);


    $scope.getServerData = function ( sSource, aoData, fnCallback ) {
        $.ajax( {
            "dataType": "json",
            "type": "GET",
            "url": sSource,
            "data": aoData,
            "success": [
                function(data) {
                    var new_data = [];
                    for (var i = 0; i < data.tmplData.length; i++) {
                        new_data[i] = [];
                        for (var j = 0; j < $scope.page.columns.length; j++) {
                            new_data[i][j] = $scope.page.columns[j].compiled(data.tmplData[i]);
                        }
                    }
                    data.aaData = new_data;
                },
                fnCallback
            ],
        } );
    };

    function compile_templates(columns) { 
        for (var idx in columns) {
            if (columns[idx].template) {
                columns[idx].compiled = Handlebars.compile(
                    columns[idx].template
                );
            }
        }
    }


}


function ColumnCtrl($scope) {

    $scope.currentColumn;
    $scope.newColumnName;


    $scope.addColumn = function () {
        $scope.currentColumn = $scope.$parent._addColumn($scope.newColumnName);
    }
}

