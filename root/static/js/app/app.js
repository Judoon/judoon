/*
 * Judoon
 * https://judoon.org/
 * https://github.com/Judoon/judoon.git
 *
 * Author:    Fitz ELLIOTT <felliott@fiskur.org>
 * Copyright: 2014 by the Rector and Visitors of the University of Virginia.
 * License:   Artistic License 2.0 (GPL Compatible)
 */

/*jshint globalstrict: true */
/*global angular */

'use strict';

var judoonApp = angular.module(
    'judoon',
    ['ngRoute', 'ngSanitize', 'ui.bootstrap', 'ui.tinymce.inline',
     'judoon.services', 'judoon.controllers', 'judoon.directives']
);

judoonApp.config(
    ['$locationProvider', '$routeProvider', '$httpProvider',
     function($locationProvider, $routeProvider, $httpProvider) {

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

         // code from:
         //   https://github.com/lavinjj/angularjs-spinner
         var $http,
             interceptor = ['$q', '$injector', function ($q, $injector) {
                 var notificationChannel;

                 function success(response) {
                     // get $http via $injector because of circular dependency problem
                     $http = $http || $injector.get('$http');
                     // don't send notification until all requests are complete
                     if ($http.pendingRequests.length < 1) {
                         // get requestNotificationChannel via $injector because of circular dependency problem
                         notificationChannel = notificationChannel || $injector.get('requestNotificationChannel');
                         // send a notification requests are complete
                         notificationChannel.requestEnded();
                     }
                     return response;
                 }

                 function error(response) {
                     // get $http via $injector because of circular dependency problem
                     $http = $http || $injector.get('$http');
                     // don't send notification until all requests are complete
                     if ($http.pendingRequests.length < 1) {
                         // get requestNotificationChannel via $injector because of circular dependency problem
                         notificationChannel = notificationChannel || $injector.get('requestNotificationChannel');
                         // send a notification requests are complete
                         notificationChannel.requestEnded();
                     }
                     return $q.reject(response);
                 }

                 return function (promise) {
                     // get requestNotificationChannel via $injector because of circular dependency problem
                     notificationChannel = notificationChannel || $injector.get('requestNotificationChannel');
                     // send a notification requests are complete
                     notificationChannel.requestStarted();
                     return promise.then(success, error);
                 };
             }];

         $httpProvider.responseInterceptors.push(interceptor);

     }
    ]
);
