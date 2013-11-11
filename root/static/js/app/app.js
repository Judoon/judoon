/*jshint globalstrict: true */
/*global angular */

'use strict';

var judoonApp = angular.module(
    'judoon',
    ['ngRoute', 'ngSanitize', 'ui.bootstrap',
     'judoon.services', 'judoon.controllers', 'judoon.directives']
);

judoonApp.config(['$locationProvider', '$routeProvider', function($locationProvider, $routeProvider) {
    $locationProvider.html5Mode(true);
    $routeProvider
        .when('/user/:userName/datasource/:datasetId', {
            templateUrl: '/static/html/partials/dataset.html',
            controller: 'DatasetCtrl'
        })
        .when('/user/:userName/page/:pageId', {
            templateUrl: '/static/html/partials/page.html',
            controller: 'PageCtrl'
        })
        .otherwise({redirectTo: '/'});
}]);
