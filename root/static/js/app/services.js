angular.module('judoonServices',['ngResource'])
    .factory('Page', function($resource) {
        return $resource('/api/page/:id', {id: '@id'}, {
            update: {method: 'PUT'}
        });
    });
