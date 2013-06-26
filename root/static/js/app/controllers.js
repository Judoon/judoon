'use strict';

/* Controllers */

function PageCtrl($scope, Page) {

    $scope.editmode = 0;

    $scope.pageId = 49;
    $scope.pageLoaded = 0;
    $scope.page = Page.get({id: $scope.pageId}, function (page) {
        for (var idx in page.columns) {
            page.columns[idx].compiled = Handlebars.compile(
                page.columns[idx].template
            );
        }
        $scope.pageLoaded = 1;
    });

    $scope.pageDirty = 0;
    $scope.$watch('page', function () { if ($scope.pageLoaded) { $scope.pageDirty = 1; } });

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
}
