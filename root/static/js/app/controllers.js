'use strict';

/* Controllers */

function PageCtrl($scope, $http) {
    $scope.pageId = 49;
    $scope.page = {};

    var init = $http.get('/api/page/'+$scope.pageId).success(function(data) {
        $scope.page = data;
        for (var idx in $scope.page.columns) {
            $scope.page.columns[idx].compiled = Handlebars.compile(
                $scope.page.columns[idx].template
            );
        }
    });

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
