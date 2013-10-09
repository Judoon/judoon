/*jshint globalstrict: true */
/*global angular */

'use strict';

var judoonSrv = angular.module('judoon.services', ['ngResource']);

judoonSrv.service('User', ['$http', function($http) {
    this.get         = function () { return $http.get('/api/user');          };
    this.getDatasets = function () { return $http.get('/api/user/datasets'); };
    this.getPages    = function () { return $http.get('/api/user/pages');    };
    this.newPage     = function (page, cb) {
        return $http.post('/api/user/pages', page)
            .success( function(data, status, getHeader) {
                $http.get(getHeader('Location')).success(cb);
            });
    };
}]);

judoonSrv.factory('Dataset', ['$resource', function($resource) {
    return $resource('/api/datasets/:id', {id: '@id'}, {
        update: {method: 'PUT'}
    });
}]);

judoonSrv.factory('DatasetPage', ['$resource', function($resource) {
    return $resource(
        '/api/datasets/:datasetId/pages',
        {datasetId: '@dataset_id'}
    );
}]);

judoonSrv.factory('DatasetColumn', ['$resource', '$http', function($resource, $http) {
    var DatasetCol = $resource(
        '/api/datasets/:datasetId/columns/:colId',
        {datasetId: '@dataset_id', colId: '@id'},
        {
            update: {method: 'PUT'}
        }
    );

    DatasetCol.saveAndFetch = function(column, cb) {
        this.save(column, function(data,  getResponseHeaders) {
            $http.get(getResponseHeaders('Location')).success(cb);
        });
    };

    return DatasetCol;
}]);

judoonSrv.factory('Page', ['$resource', '$http', function($resource, $http) {
    var Page = $resource('/api/pages/:id', {id: '@id'}, {
        update: {method: 'PUT'}
    });

    Page.saveAndFetch = function(column, cb) {
        this.save(column, function(data,  getResponseHeaders) {
            $http.get(getResponseHeaders('Location')).success(cb);
        });
    };

    return Page;
}]);

judoonSrv.factory('PageColumn', ['$resource', '$http', function($resource, $http) {
    var PageCol = $resource(
        '/api/pages/:pageId/columns/:colId',
        {pageId: '@page_id', colId: '@id'},
        {
            update: {method: 'PUT'}
        }
    );

    PageCol.saveAndFetch = function(column, cb) {
        this.save(column, function(data,  getResponseHeaders) {
            $http.get(getResponseHeaders('Location')).success(cb);
        });
    };

    return PageCol;
}]);


judoonSrv.factory('DataType', ['$resource', function($resource) {
    return $resource(
        '/api/datatype/:typeId',
        {typeId: '@id'}
    );
}]);


judoonSrv.factory('Lookup', ['$resource', function($resource) {
    var Lookup = $resource(
        '/api/lookup/:group_id/:id/:io/:input_id/:sub_io',
        {
            group_id: '@group_id',
            id:       '@id',
            io:       '@io',
            input_id: '@input_id',
            sub_io:   '@sub_io'
        }
    );

    return Lookup;
}]);
