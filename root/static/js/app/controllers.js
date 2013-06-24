'use strict';

/* Controllers */

function PageCtrl($scope, $http) {
  $scope.pageId = 49;

  $http.get('/api/page/'+$scope.pageId).success(function(data) {
      $scope.page = data;
  });

}
