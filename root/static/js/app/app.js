/*jshint globalstrict: true */
/*global angular */

'use strict';

var judoonApp = angular.module(
    'judoon',
    ['ngRoute', 'ngSanitize', 'ui.bootstrap', 'ui.tinymce.inline',
     'judoon.services', 'judoon.controllers', 'judoon.directives']
);

judoonApp.config(
    ['$locationProvider', '$routeProvider',
     function($locationProvider, $routeProvider) {

         $locationProvider.html5Mode(true);
         $routeProvider
             .when('/users/:userName', {
                 templateUrl    : '/static/html/partials/user.html',
                 controller     : 'UserCtrl',
                 reloadOnSearch : false,
                 resolve        : {
                     user: ['$route', 'User', function($route, User) {
                         var userName = $route.current.params.userName;
                         return User.get(userName);
                     }]
                 }
             })
             .when('/users/:userName/datasets/:datasetId', {
                 templateUrl    : '/static/html/partials/dataset.html',
                 controller     : 'DatasetCtrl',
                 reloadOnSearch : false,
                 resolve        : {
                     user: ['$route', 'User', function($route, User) {
                         var userName = $route.current.params.userName;
                         return User.get(userName);
                     }],
                     dataset: ['$route', 'Dataset', function($route, Dataset) {
                         var datasetId = $route.current.params.datasetId;
                         return Dataset.get(datasetId);
                     }]
                 }
             })
             .when('/users/:userName/views/:pageId', {
                 templateUrl: '/static/html/partials/page.html',
                 controller: 'PageCtrl',
                 resolve: {
                     user: ['$route', 'User', function($route, User) {
                         var userName = $route.current.params.userName;
                         return User.get(userName);
                     }],
                     page: ['$route', 'Pages', function($route, Pages) {
                         var pageId = $route.current.params.pageId;
                         return Pages.get(pageId);
                     }],
                     welcome: ['$route', function($route) {
                         return !!$route.current.params.welcome;
                     }]
                 }
             })
             .otherwise({redirectTo: '/'});
     }
    ]
);
