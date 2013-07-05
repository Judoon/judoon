'use strict';

var judoonSrv = angular.module('judoon.services', ['ngResource']);

judoonSrv.factory('Page', ['$resource', function($resource) {
    return $resource('/api/page/:id', {id: '@id'}, {
        update: {method: 'PUT'}
    });
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
