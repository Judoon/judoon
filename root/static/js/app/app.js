/*jshint globalstrict: true */
/*global angular */

'use strict';

var judoonApp = angular.module(
    'judoon',
    ['ngRoute', 'ngSanitize', 'contenteditable', 'ui.bootstrap',
     'judoon.services', 'judoon.controllers', 'judoon.directives']
);

judoonApp.config(
    ['$locationProvider', '$routeProvider',
     function($locationProvider, $routeProvider) {

         $locationProvider.html5Mode(true);
         $routeProvider
             .when('/user/:userName', {
                 templateUrl    : '/static/html/partials/user.html',
                 controller     : 'UserCtrl',
                 reloadOnSearch : false,
                 resolve        : {
                     user: ['$route', 'Userp', function($route, Userp) {
                         var userName = $route.current.params.userName;
                         return Userp.get(userName);
                     }]
                 }
             })
             .when('/user/:userName/dataset/:datasetId', {
                 templateUrl: '/static/html/partials/dataset.html',
                 controller: 'DatasetCtrl'
             })
             .when('/user/:userName/page/:pageId', {
                 templateUrl: '/static/html/partials/page.html',
                 controller: 'PageCtrl'
             })
             .otherwise({redirectTo: '/'});
     }
    ]
);
