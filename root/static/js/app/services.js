var judoonSrv = angular.module('judoonServices',['ngResource']);

judoonSrv.factory('Page', function($resource) {
    return $resource('/api/page/:id', {id: '@id'}, {
        update: {method: 'PUT'}
    });
});

judoonSrv.factory('PageColumn', function($resource) {
    return $resource(
        '/api/page/:pageId/column/:colId',
        {pageId: '@page_id', colId: '@id',}, {
            update: {method: 'PUT'}
        }
    );
});
