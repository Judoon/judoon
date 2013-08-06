'use strict';

var judoonApp = angular.module(
    'judoon',
    ['ui.bootstrap','judoon.services','judoon.controllers','judoon.directives']
);

judoonApp.config(['$locationProvider', '$routeProvider', function($locationProvider, $routeProvider) {
    $locationProvider.html5Mode(true);
    $routeProvider
        .when('/user/:userName/page/:pageId', {
            templateUrl: '/static/html/partials/page.html',
            controller: 'PageCtrl'
        })
        .when('/user/:userName/dataset/:datasetId/column', {
            templateUrl: '/static/html/partials/dscolumn.html',
            controller: 'DatasetColumnCtrl'
        })
        .otherwise({redirectTo: '/'});
}]);
