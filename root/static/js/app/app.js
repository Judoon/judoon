'use strict';

var judoonApp = angular.module('judoon', ['judoon.services','judoon.controllers','judoon.directives']);

judoonApp.config(['$locationProvider', '$routeProvider', function($locationProvider, $routeProvider) {
    $locationProvider.html5Mode(true);
    $routeProvider
        .when('/user/:userName/fancy/page/:pageId', {templateUrl: '/static/html/partials/page.html', controller: 'PageCtrl'})
        .otherwise({redirectTo: '/'});
}]);
