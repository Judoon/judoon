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


    $scope._rmColumn = function(deleteColumn) {
        for (var idx in $scope.page.columns) {
            if ($scope.page.columns[idx] === deleteColumn) {
                $scope.page.columns.splice(idx, 1);
            }
        }
    };


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
    $scope.deleteColumn;

    $scope.addColumn = function () {
        $scope.currentColumn = $scope.$parent._addColumn($scope.newColumnName);
    }


    $scope.removeColumn = function() {
        if (!$scope.deleteColumn) {
            return false;
        }

        var deleteColumn = confirm("Are you sure you want to delete this column?");
        if (deleteColumn) {
            if ($scope.currentColumn === $scope.deleteColumn) {
                $scope.currentColumn = null;
            }

            $scope.$parent._rmColumn($scope.deleteColumn);
        }
    }
}

