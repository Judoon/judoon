/*jshint globalstrict: true */
/*global angular,_ */

'use strict';

var judoonSrv = angular.module('judoon.services', ['ngResource']);

// Yes, I'm basically reimplementing ngResource here...
judoonSrv.factory('DataType', ['$http', function($http) {
    var wrapper = {};

    return {
        get: function(typeId) {
            var promise,
                value = {},
                _this = this;

            promise = $http.get('/api/datatype/' + typeId).then(
                function(response) {
                    var data = response.data,
                        promise = value.$promise;

                    angular.copy(_this._buildDataType(data), value);

                    value.$resolved = true;
                    response.resource = value;
                    return response;
                }
            );

            value.$promise  = promise;
            value.$resolved = false;
            return value;
        },
        query: function() {
            var promise,
                _this = this,
                value = [];
            
            promise = $http.get('/api/datatype').then( function(response) {
                var data = response.data,
                    promise = value.$promise;

                value.length = 0;
                angular.forEach(data, function(dataType) {
                    value.push(_this._buildDataType(dataType));
                });

                value.$resolved = true;
                response.resource = value;
                return response;
            });

            value.$promise  = promise;
            value.$resolved = false;
            return value;
        },
        _buildDataType: function(dataType) {
            _.extend(dataType, wrapper);
            return dataType;
        }
    };
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
    var _this = this;
    _this.alerts = [];

    function curryAlert(type) {
        return function(msg) { _this.alerts.push({type: type, msg: msg}); };
    }
    function closeAlertAt(index) {
        _this.alerts.splice(index, 1);
    }

    _this.alertSuccess = curryAlert('success');
    _this.alertError   = curryAlert('error');
    _this.alertWarning = curryAlert('warning');
    _this.alertInfo    = curryAlert('info');
    _this.closeAlert   = closeAlertAt;
}]);


judoonSrv.factory(
    'User',
    ['$http', 'Dataset', 'Pages', function($http, Dataset, Pages) {

        var wrapper = {
            getDatasets: function() {
                var future,
                    _this = this;
                future = $http.get('/api/user/datasets');
                return future.then(function(response) {
                    _this.datasets = [];
                    angular.forEach(response.data, function(value) {
                        _this.datasets.push(Dataset._buildDataset(value));
                        _this.datasetsLoaded = 1;
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
                var promise,
                    _this = this,
                    value = [];

                promise = $http.get('/api/user/pages').then(
                    function(response) {
                        var data = response.data,
                            promise = value.$promise;

                        value.length = 0;
                        angular.forEach(data, function(page) {
                            value.push(Pages._buildPage(page));
                        });

                        value.$resolved = true;
                        response.resource = value;
                        return response;
                    });

                value.$promise  = promise;
                value.$resolved = false;
                return value;
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
                .then(function(_this) {
                    _this.getDatasets().then( function(datasets) {
                        angular.forEach(datasets, function(dsValue) {
                            dsValue.getColumns();
                            dsValue.pages = dsValue.getPages();
                        });
                    });
                    _this.pages = _this.getPages();
                    return _this;
                });
            },
            _buildUser: function(user) {
                _.extend(user, wrapper);
                return user;
            }
        };
    }]
);


judoonSrv.factory(
    'Dataset',
    ['$http', 'Pages', 'DatasetColumns',
     function($http, Pages, DatasetColumns) {
         var apiBase = '/api/datasets/';

         var wrapper = {
             url: function() {
                 var _this = this;
                 return apiBase + _this.id;
             },
             update: function() {
                 var future,
                     _this = this;
                 future = $http.put(_this.url(), {
                     name:        _this.name,
                     description: _this.description,
                     permission:  _this.permission
                 });
                 return future;
             },
        deleteMe: function() {
            var future,
                _this = this;
            future = $http.delete(_this.url());
            return future;
        },
        getColumns: function() {
            var future,
                _this = this;
            future = $http.get(_this.url() + '/columns');
            return future.then(function(response) {
                _this.columns = [];
                angular.forEach(response.data, function(value) {
                    _this.columns.push(DatasetColumns._buildDatasetColumn(value));
                });
                _this.columnsLoaded = 1;
                return _this.columns;
            });
        },
        createColumn: function (newColumnSpec) {
            var _this = this;
            return $http.post(_this.url() + '/columns', newColumnSpec)
                .then( function(response) {
                    return $http.get(response.headers('Location'))
                        .then( function(response) {
                            var column = DatasetColumns._buildDatasetColumn(response.data);
                            _this.columns.push(column);
                            return column;
                        } );
                });
        },
        getPages: function() {
            var promise,
                _this = this,
                value = [];

            promise = $http.get(_this.url() + '/pages').then(
                function(response) {
                    var data = response.data,
                        promise = value.$promise;

                    value.length = 0;
                    angular.forEach(data, function(page) {
                        value.push(Pages._buildPage(page));
                    });
                    
                    value.$resolved = true;
                    response.resource = value;
                    return response;
                }
            );

            value.$promise  = promise;
            value.$resolved = false;
            return value;
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
                .then( function(response) {
                    return $http.get(response.headers('Location'))
                        .then( function(response) {
                            var page = Pages._buildPage(response.data);
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
            future = $http.get(apiBase + datasetId);
            return future.then(
                function(response) { return _this._buildDataset(response.data); }
            )
            .then(
                function(_this) {
                    _this.getColumns();
                    _this.pages = _this.getPages();
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
    'DatasetColumns', ['$http', function($http) {
        var wrapper = {
            url: function() {
                var _this = this;
                return '/api/datasets/' + _this.dataset_id + '/columns/' +
                    _this.id;
            },
            update: function() {
                var future,
                    _this = this;
                future = $http.put(_this.url(), {data_type: _this.data_type});
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
    'Pages',
    ['$http', 'PageColumns', function($http, PageColumns) {
        var apiBase = '/api/pages/';

        var wrapper = {
            url: function() {
                var _this = this;
                return apiBase + _this.id;
            },
            update: function() {
                var future,
                    _this = this;
                future = $http.put(_this.url(), {
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
                future = $http.get(_this.url() + '/columns');
                return future.then(function(response) {
                    _this.columns = [];
                    angular.forEach(response.data, function(value) {
                        _this.columns.push(PageColumns._buildPageColumn(value));
                    });
                    _this.columnsLoaded = 1;
                    return _this.columns;
                });
            },
            createColumn: function (newColumn) {
                var _this = this;
                newColumn.template = '';
                return $http.post(_this.url() + '/columns', newColumn)
                    .then( function(response) {
                        return $http.get(response.headers('Location'))
                            .then( function(response) {
                                var column = PageColumns._buildPageColumn(response.data);
                                _this.columns.push(column);
                                return column;
                            } );
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
                future = $http.delete(_this.url());
                return future;
            }
        };

        return {
            get: function(pageId) {
                var future,
                    _this = this;
                future = $http.get(apiBase + pageId);
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
    'PageColumns', ['$http', function($http) {

        var wrapper = {
            url: function() {
                var _this = this;
                return '/api/pages/' + _this.page_id + '/columns/' + _this.id;
            },
            update: function(sort) {
                var future,
                    _this = this;
                future = $http.put(
                    _this.url(),
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
                future = $http.delete(_this.url());
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
