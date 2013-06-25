angular.module('judoonServices',['ngResource'])
    .factory('Page', function($resource) {
        return $resource('/api/page/:pageId', {}, {
            query: {method: 'GET', params: {pageId:'???'}, isArray: true}
        });
    });
