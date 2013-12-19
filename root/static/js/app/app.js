/*jshint globalstrict: true */
/*global angular */

'use strict';

var judoonApp = angular.module(
    'judoon',
    ['ngRoute', 'ngSanitize', 'ui.bootstrap', 'ui.tinymce.inline',
     'judoon.services', 'judoon.controllers', 'judoon.directives']
);

judoonApp.constant('_START_REQUEST_', '_START_REQUEST_');
judoonApp.constant('_END_REQUEST_', '_END_REQUEST_');

judoonApp.config(
    ['$locationProvider', '$routeProvider', '$httpProvider',
     '_START_REQUEST_', '_END_REQUEST_',
     function($locationProvider, $routeProvider, $httpProvider,
              _START_REQUEST_, _END_REQUEST_) {

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

         var $http,
             interceptor = ['$q', '$injector', function ($q, $injector) {
                 var rootScope;

                 function success(response) {
                     // get $http via $injector because of circular dependency problem
                     $http = $http || $injector.get('$http');
                     // don't send notification until all requests are complete
                     if ($http.pendingRequests.length < 1) {
                         // get $rootScope via $injector because of circular dependency problem
                         rootScope = rootScope || $injector.get('$rootScope');
                         // send a notification requests are complete
                         rootScope.$broadcast(_END_REQUEST_);
                     }
                     return response;
                 }

                 function error(response) {
                     // get $http via $injector because of circular dependency problem
                     $http = $http || $injector.get('$http');
                     // don't send notification until all requests are complete
                     if ($http.pendingRequests.length < 1) {
                         // get $rootScope via $injector because of circular dependency problem
                         rootScope = rootScope || $injector.get('$rootScope');
                         // send a notification requests are complete
                         rootScope.$broadcast(_END_REQUEST_);
                     }
                     return $q.reject(response);
                 }

                 return function (promise) {
                     // get $rootScope via $injector because of circular dependency problem
                     rootScope = rootScope || $injector.get('$rootScope');
                     // send notification a request has started
                     rootScope.$broadcast(_START_REQUEST_);
                     return promise.then(success, error);
                 };
             }];

         $httpProvider.responseInterceptors.push(interceptor);
     }
    ]
);
