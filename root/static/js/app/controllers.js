'use strict';

/* Controllers */

function PageCtrl($scope, $routeParams, Page, PageColumn) {

    // Attributes
    $scope.editmode = 0;

    $scope.pageId = $routeParams.pageId;
    $scope.pageLoaded = 0;
    Page.get({id: $scope.pageId}, function (page) {
        $scope.page = page;
        $scope.pageLoaded = 1;
        $scope.pageOriginal = angular.copy($scope.page);
    });

    $scope.pageDirty = 0;
    $scope.$watch('page', function () {
        if ($scope.pageLoaded) {
            $scope.pageDirty = 1;
        }
    }, true);

    $scope.newColumnName;
    $scope.currentColumn;
    $scope.deleteColumn;
    PageColumn.query({}, {page_id: $scope.pageId}, function (columns) {
        $scope.pageColumns = columns;
    });


    // Methods
    $scope.updatePage = function(){
        Page.update({
            id:         $scope.pageId,
            title:      $scope.page.title,
            preamble:   $scope.page.preamble,
            postamble:  $scope.page.postamble,
            dataset_id: $scope.page.dataset_id,
        });

        angular.forEach($scope.pageColumns, function (value, key) {
            PageColumn.update({
                page_id:  value.page_id,
                id:       value.id,
                title:    value.title,
                template: value.template
            });
        } );
    };

    $scope.addColumn = function() {
        var newColumn = {
            title: $scope.newColumnName,
            template: '',
            page_id: $scope.pageId
        };

        PageColumn.saveAndFetch(newColumn, function(fullCol) {
            $scope.pageColumns.push(fullCol);
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
                {}, {page_id: $scope.pageId, id: $scope.deleteColumn.id},
                function() {
                    if (angular.equals($scope.currentColumn, $scope.deleteColumn)) {
                        $scope.currentColumn = null;
                    }

                    angular.forEach($scope.pageColumns, function (value, key) {
                        if ( angular.equals(value, $scope.deleteColumn) ) {
                            $scope.pageColumns.splice(key, 1);
                        }
                    } );
                }
            );
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
                    var templates = [];
                    angular.forEach($scope.pageColumns, function (value, key) {
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

