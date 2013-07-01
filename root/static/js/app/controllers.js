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
                    for (var idx in $scope.page.columns) {
                        templates.push(
                            Handlebars.compile(
                                $scope.page.columns[idx].template
                            )
                        );
                    }

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

    $scope.currentColumn;
    $scope.newColumnName;
    $scope.deleteColumn;


    $scope.addColumn = function() {
        var newColumn = {
            title: $scope.newColumnName,
            template: '',
            page_id: $scope.pageId
        };

        // PageColumn.save(newColumn, function(data, getResponseHeaders) {
        //     var headers = getResponseHeaders();
        //     $http.get(headers.location).success(
        //         function(fullCol) {
        //             $scope.$parent.page.columns.push(fullCol);
        //             $scope.currentColumn = fullCol;
        //         }
        //     );
        // } );

        $scope.columns.saveAndFetch(newColumn, function(fullCol) {
            $scope.columns.push(fullCol);
            $scope.currentColumn = fullCol;
        });

        var thonk = 3;
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
                    if ($scope.currentColumn === $scope.deleteColumn) {
                        $scope.currentColumn = null;
                    }

                    for (var idx in $scope.$parent.page.columns) {
                        if ($scope.$parent.page.columns[idx] === $scope.deleteColumn) {
                            $scope.$parent.page.columns.splice(idx, 1);
                        }
                    }
                }
            );
        }
    };
}

