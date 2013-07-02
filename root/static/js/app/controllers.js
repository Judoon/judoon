'use strict';

/* Controllers */

function PageCtrl($scope, $routeParams, Page) {

    $scope.editmode = 0;

    $scope.pageId = $routeParams.pageId;
    $scope.pageLoaded = 0;
    $scope.page = Page.get({id: $scope.pageId}, function (page) {
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

    $scope.getServerData = function ( sSource, aoData, fnCallback ) {
        $.ajax( {
            "dataType": "json",
            "type": "GET",
            "url": sSource,
            "data": aoData,
            "success": [
                function(data) {
                    var templates = [];
                    angular.forEach($scope.page.columns, function (value, key) {
                        templates.push( Handlebars.compile(value.template) );
                    } );

                    var new_data = [];
                    for (var i = 0; i < data.tmplData.length; i++) {
                        new_data[i] = [];
                        for (var j = 0; j < templates.length; j++) {
                            new_data[i][j] = templates[j](data.tmplData[i]);
                        }
                    }
                    data.aaData = new_data;
                },
                fnCallback
            ],
        } );
    };
}


function ColumnCtrl($scope, PageColumn) {

    $scope.newColumnName;
    $scope.currentColumn;
    $scope.deleteColumn;


    $scope.addColumn = function() {
        var newColumn = {
            title: $scope.newColumnName,
            template: '',
            page_id: $scope.pageId
        };

        PageColumn.saveAndFetch(newColumn, function(fullCol) {
            $scope.$parent.page.columns.push(fullCol);
            $scope.currentColumn = fullCol;
        } );
    };

    $scope.removeColumn = function() {
        if (!$scope.deleteColumn) {
            return false;
        }

        var confirmed = confirm("Are you sure you want to delete this column?");
        if (confirmed) {
            PageColumn.delete(
                {}, {page_id: $scope.deleteColumn.page_id, id: $scope.deleteColumn.id},
                function() {
                    if (angular.equals($scope.currentColumn, $scope.deleteColumn)) {
                        $scope.currentColumn = null;
                    }

                    angular.forEach($scope.$parent.page.columns, function (value, key) {
                        if ( angular.equals(value, $scope.deleteColumn) ) {
                            $scope.$parent.page.columns.splice(key, 1);
                        }
                    } );
                }
            );
        }
    };
}

