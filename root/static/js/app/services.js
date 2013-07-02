var judoonSrv = angular.module('judoonServices',['ngResource']);

judoonSrv.factory('Page', function($resource) {
    return $resource('/api/page/:id', {id: '@id'}, {
        update: {method: 'PUT'}
    });
});

judoonSrv.factory('PageColumn', function($resource, $http) {
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
});
