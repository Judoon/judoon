/*jshint globalstrict: true */
/*global angular,_ */

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


judoonSrv.service('Alerts', [function() {
    this.alerts = [];

    function curryAlert(type) {
        return function(msg) { this.alerts.push({type: type, msg: msg}); };
    }
    function closeAlertAt(index) {
        this.alerts.splice(index, 1);
    }

    this.alertSuccess = curryAlert('success');
    this.alertError   = curryAlert('error');
    this.alertWarning = curryAlert('warning');
    this.alertInfo    = curryAlert('info');
    this.closeAlert   = closeAlertAt;
}]);


judoonSrv.factory(
    'Userp',
    ['$http', 'Datasetp', 'Pagesp', function($http, Datasetp, Pagesp) {

        var wrapper = {
            getDatasets: function() {
                var future,
                    _this = this;
                future = $http.get('/api/user/datasets');
                return future.then(function(response) {
                    _this.datasets = [];
                    angular.forEach(response.data, function(value) {
                        _this.datasets.push(Datasetp._buildDataset(value));
                    });
                    return _this.datasets;
                });
            },
            createDataset: function(content) {
                var future,
                    _this = this;
                future = $http.post('/api/user/datasets', {});
                return future.then(function(response) {
                    var post = response.data;
                    _this.datasets.push(post);
                    return post;
                });
            },
            deleteDataset: function(dataset) {
                var _this = this;
                return dataset.deleteMe().then(function() {
                    var idx = _this.datasets.indexOf( dataset );
                    _this.datasets.splice(idx, 1);
                    return dataset;
                });
            },
            selectedDataset: null,
            setSelectedDataset: function (dataset) {
                var _this = this,
                    idx   = _this.datasets.indexOf(dataset);
                _this.selectedDataset = _this.datasets[idx];
            },
            getPages: function() {
                var future,
                    _this = this;
                future = $http.get('/api/user/pages');
                return future.then(function(response) {
                    _this.pages = [];
                    angular.forEach(response.data, function(value) {
                        _this.pages.push(Pagesp._buildPage(value));
                    });
                    return _this.pages;
                });
            }
        };


        return {
            get: function() {
                var future,
                    _this = this;
                future = $http.get('/api/user');
                return future.then(
                    function(response) { return _this._buildUser(response.data); }
                )
                    .then(
                        function(_this) {
                            _this.getDatasets().then(
                                function(datasets) {
                                    angular.forEach(datasets, function(value) {
                                        value.getColumns();
                                        value.getPages().then(
                                            function(pages) {
                                                angular.forEach(pages, function(value) {
                                                    value.getColumns();
                                                });
                                            }
                                        );
                                    });
                                }
                            );
                            return _this;
                        }
                    );
            },
            _buildUser: function(user) {
                _.extend(user, wrapper);
                return user;
            }
        };
    }]
);


judoonSrv.factory(
    'Datasetp',
    ['$http', 'Pagesp', 'DatasetColumnsp', function($http, Pagesp, DatasetColumnsp) {
    var wrapper = {
        update: function() {
            var future,
                _this = this;
            future = $http.put('/api/datasets/' + _this.id, {
                name:        _this.name,
                description: _this.description,
                permission:  _this.permission
            });
            return future;
        },
        deleteMe: function() {
            var future,
                _this = this;
            future = $http.delete('/api/datasets/' + _this.id);
            return future;
        },
        getColumns: function() {
            var future,
                _this = this;
            future = $http.get('/api/datasets/' + _this.id + '/columns');
            return future.then(function(response) {
                _this.columns = [];
                angular.forEach(response.data, function(value) {
                    _this.columns.push(DatasetColumnsp._buildDatasetColumn(value));
                });
                return _this.columns;
            });
        },
        getPages: function() {
            var future,
                _this = this;
            future = $http.get('/api/datasets/' + _this.id + '/pages');
            return future.then(function(response) {
                _this.pages = [];
                angular.forEach(response.data, function(value) {
                    _this.pages.push(Pagesp._buildPage(value));
                });
                return _this.pages;
            });
        },
        createPage: function (newPage) {
            var _this = this;
            if (!newPage) {
                newPage = {};
            }
            if (!newPage.type) {
                newPage.type = 'blank';
            }
            newPage.dataset_id = _this.id;
            return $http.post('/api/user/pages', newPage)
                .success( function(data, status, getHeader) {
                    $http.get(getHeader('Location'))
                        .success( function(pageData) {
                            var page = Pagesp._buildPage(pageData);
                            _this.pages.push(page);
                            return page;
                        } );
                });
        },
        deletePage: function(page) {
            var _this = this;
            return page.deleteMe().then(function() {
                var idx = _this.pages.indexOf( page );
                _this.pages.splice(idx, 1);
                return page;
            });
        }
    };
    return {
        get: function(datasetId) {
            var future,
                _this = this;
            future = $http.get('/api/datasets/' + datasetId);
            return future.then(
                function(response) { return _this._buildDataset(response.data); }
            )
            .then(
                function(_this) {
                    _this.getColumns();
                    _this.getPages();
                    return _this;
                }
            );
        },
        _buildDataset: function(dataset) {
            _.extend(dataset, wrapper);
            return dataset;
        }
    };
    }]
);


judoonSrv.factory(
    'DatasetColumnsp', ['$http', function($http) {
        var wrapper = {
            update: function() {
                var future,
                    _this = this;
                future = $http.put(
                    '/api/datasets/' + _this.dataset_id + '/columns/' +
                        _this.id,
                    {data_type:  _this.data_type}
                );
                return future;
            }
        };
        return {
            get: function(datasetId, datasetColId) {
                var future,
                    _this = this;
                future = $http.get('/api/datasets/' + datasetId + '/columns/' +
                                   datasetColId);
                return future.then(
                    function(response) {
                        return _this._buildDatasetColumn(response.data);
                    }
                );
            },
            _buildDatasetColumn: function(datasetcolumn) {
                _.extend(datasetcolumn, wrapper);
                return datasetcolumn;
            }
        };
    }]
);



judoonSrv.factory(
    'Pagesp',
    ['$http', '$sce', 'PageColumnsp', function($http, $sce, PageColumnsp) {
        var wrapper = {
            update: function() {
                var future,
                    _this = this;
                future = $http.put('/api/pages/' + _this.id, {
                    title:      _this.title,
                    preamble:   _this.preamble,
                    postamble:  _this.postamble,
                    permission: _this.permission
                });
                return future;
            },
            getColumns: function() {
                var future,
                    _this = this;
                future = $http.get('/api/pages/' + _this.id + '/columns');
                return future.then(function(response) {
                    _this.columns = [];
                    angular.forEach(response.data, function(value) {
                        _this.columns.push(PageColumnsp._buildPageColumn(value));
                    });
                    return _this.columns;
                });
            },
            createColumn: function (newColumn) {
                var _this = this;
                newColumn.template = '';
                return $http.post('/api/pages/' + _this.id, newColumn)
                    .success( function(data, status, getHeader) {
                        var column = $http.get(getHeader('Location'))
                                .success( function(columnData) {
                                    return PageColumnsp._buildPageColumn(columnData);
                                } );
                        _this.columns.push(column);
                        return column;
                    });
            },
            deleteColumn: function(column) {
                var _this = this;
                column.deleteMe().then(function() {
                    var idx = _this.columns.indexOf( column );
                    _this.columns.splice(idx, 1);
                    return column;
                });

            },
            deleteMe: function() {
                var future,
                    _this = this;
                future = $http.delete('/api/pages/' + _this.id);
                return future;
            }
        };

        return {
            get: function(pageId) {
                var future,
                    _this = this;
                future = $http.get('/api/pages/' + pageId);
                return future.then(
                    function(response) { return _this._buildPage(response.data); }
                )
                    .then(
                        function(_this) { _this.getColumns(); return _this; }
                    );
            },
            _buildPage: function(page) {
                _.extend(page, wrapper);
                return page;
            }
        };
    }]
);


judoonSrv.factory(
    'PageColumnsp', ['$http', function($http) {
        var wrapper = {
            update: function(sort) {
                var future,
                    _this = this;
                future = $http.put(
                    '/api/pages/' + _this.page_id + '/columns/' + _this.id,
                    {
                        title:   _this.title,
                        widgets: _this.widgets,
                        sort:    sort
                    }
                );
                return future;
            },
            deleteMe: function() {
                var future,
                    _this = this;
                future = $http.delete('/api/pages/' + _this.page_id + '/column/' + _this.id);
                return future;
            }
        };
        return {
            get: function(pageId, pageColId) {
                var future,
                    _this = this;
                future = $http.get('/api/pages/' + pageId + '/columns/' +
                                   pageColId);
                return future.then(
                    function(response) {
                        return _this._buildPageColumn(response.data);
                    }
                );
            },
            _buildPageColumn: function(pagecolumn) {
                _.extend(pagecolumn, wrapper);
                return pagecolumn;
            }
        };
    }]
);
