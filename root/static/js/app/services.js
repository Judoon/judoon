/*jshint globalstrict: true */
/*global angular */

'use strict';

var judoonSrv = angular.module('judoon.services', ['ngResource']);

judoonSrv.factory('Dataset', ['$resource', function($resource) {
    return $resource('/api/dataset/:id', {id: '@id'}, {
        update: {method: 'PUT'}
    });
}]);

judoonSrv.factory('DatasetPage', ['$resource', function($resource) {
    return $resource(
        '/api/dataset/:datasetId/page/:pageId',
        {datasetId: '@dataset_id', pageId: '@page_id'}
    );
}]);

judoonSrv.factory('DatasetColumn', ['$resource', '$http', function($resource, $http) {
    var DatasetCol = $resource(
        '/api/dataset/:datasetId/column/:colId',
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
    var Page = $resource('/api/page/:id', {id: '@id'}, {
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
        '/api/page/:pageId/column/:colId',
        {pageId: '@page_id', colId: '@id',},
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


judoonSrv.factory('Transform', ['$resource', function($resource) {
    return $resource(
        '/api/transform/:transformType/:transform',
        {transformType: '@id'}
    );
}]);


judoonSrv.factory('DataType', ['$resource', function($resource) {
    return $resource(
        '/api/datatype/:typeId',
        {typeId: '@id'}
    );
}]);

judoonSrv.factory('Transform', ['$resource', function($resource) {
    return $resource(
        '/api/transform/:transformType/:transform',
        {transformType: '@id'}
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

    Lookup.getInputs = function () {
        this.input_columns = this.$get({},{io: 'input'});
    };

    return Lookup;
}]);
