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

    angular.extend(PageCol.prototype, {
        saveAndFetch: function(column, cb) {
            this.$save(column, function(data,  getResponseHeaders) {
                var headers = getResponseHeaders();
                $http.get(headers.location).success(cb);
            });
        }
    });

    return PageCol;
});
