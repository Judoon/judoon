/*jshint globalstrict: true */
/*jshint jquery: true */
/*global angular, Handlebars, window */

'use strict';

var judoonCtrl = angular.module('judoon.controllers', []);

judoonCtrl.controller(
    'DatasetCtrl',
    ['$scope', '$routeParams', '$http', 'Dataset', 'DatasetColumn', 'Page', 'DatasetPage', 'DataType',
     function ($scope, $routeParams, $http, Dataset, DatasetColumn, Page, DatasetPage, DataType) {

         // *** View property defaults
         $scope.hideProperties = false;
         $scope.hideData       = true;
         $scope.hideColumns    = true;
         $scope.hidePages      = true;


         // *** Alerts ***
         $scope.alerts = [];
         $scope.addAlert = function(type, msg) {
             $scope.alerts.push({type: type, msg: msg});
         };
         $scope.closeAlert = function(index) {
             $scope.alerts.splice(index, 1);
         };


         // *** Dataset ***
         $scope.userName  = $routeParams.userName;
         $scope.datasetId = $routeParams.datasetId;
         Dataset.get({id: $scope.datasetId}, function (dataset) {
             $scope.datasetOriginal = angular.copy(dataset);
             $scope.dataset = dataset;
         });

         $scope.permissions = [
             {label: 'No', value: 'private'},
             {label: 'Yes', value: 'public'}
         ];

         $scope.saveDataset = function() {
             Dataset.update(
                 {}, {
                     id:         $scope.datasetId,
                     name:       $scope.dataset.name,
                     notes:      $scope.dataset.notes,
                     permission: $scope.dataset.permission
                 },
                 function() { $scope.addAlert('success', 'Dataset updated!'); },
                 function() { $scope.addAlert('error', 'Something went wrong!'); }
             );
             $scope.datasetOriginal = $scope.dataset;
         };

         $scope.resetDataset = function() {
             $scope.dataset = angular.copy($scope.datasetOriginal);
         };


         // *** Dataset Columns ***
         DatasetColumn.query({}, {dataset_id: $scope.datasetId}, function (columns) {
             $scope.dataset.columns = columns;
             $scope.dsColumnsLoaded = 1;
             $scope.dsColumnsOriginal = angular.copy(columns);
         });

         $scope.saveColumns = function() {
             angular.forEach($scope.dataset.columns, function (value, key) {
                 if (!angular.equals($scope.dsColumnsOriginal[key], value)) {
                     DatasetColumn.update({
                         dataset_id:  value.dataset_id,
                         id:          value.id,
                         data_type:   value.data_type
                     });
                     $scope.dsColumnsOriginal[key] = angular.copy(value);
                 }
             } );
         };


         // *** Pages ***
         DatasetPage.query({}, {dataset_id: $scope.datasetId}, function (pages) {
             $scope.dataset.pages = pages;
         });

         Page.query({}, function (pages) { $scope.allPages = pages; });

         $scope.newPage = {type: 'blank', dataset_id: $scope.datasetId};
         $scope.createPage = function() {
             Page.saveAndFetch($scope.newPage, function(page) {
                 $scope.dataset.pages.push(page);
             });
         };


         $scope.getServerData = function ( sSource, aoData, fnCallback ) {
             $.ajax( {
                 "dataType" : "json",
                 "type"     : "GET",
                 "url"      : sSource,
                 "data"     : aoData,
                 "success": [
                     function(data) {
                         var new_data = [];
                         for (var i = 0; i < data.tmplData.length; i++) {
                             new_data[i] = [];
                             for (var j = 0; j < $scope.dataset.columns.length; j++) {
                                 new_data[i][j] = data.tmplData[i][$scope.dataset.columns[j].shortname];
                             }
                         }
                         data.aaData = new_data;
                     },
                     fnCallback
                 ],
             } );
         };


         // *** DataTypes ***
         DataType.query({}, {}, function (data_types) {
             $scope.data_types = data_types;
         });

     }
    ]
);



judoonCtrl.controller(
    'PageCtrl',
    ['$scope', '$routeParams', '$http',
     'Page', 'PageColumn', 'Dataset', 'DatasetColumn',
     function ($scope, $routeParams, $http, Page, PageColumn, Dataset, DatasetColumn) {

    // Attributes
    $scope.editmode = 0;

    $scope.userName = $routeParams.userName;
    $scope.pageId = $routeParams.pageId;
    $scope.pageLoaded = 0;
    Page.get({id: $scope.pageId}, function (page) {
        $scope.pageOriginal = angular.copy(page);
        $scope.page = page;
        $scope.pageLoaded = 1;
        Dataset.get({id: page.dataset_id}, function (ds) {
            $scope.dataset = ds;
        });

        DatasetColumn.query({}, {dataset_id: page.dataset_id}, function (columns) {
            $scope.dataset.columns = columns;
            $scope.dsColumnsLoaded = 1;
            $scope.dsColumnsOriginal = angular.copy(columns);

            $scope.ds_columns = {accessions: [], dict: {}};
            angular.forEach(columns, function(value, key) {
                $scope.ds_columns.dict[value.shortname] = value;
                if (value.data_type.match(/accession/i)) {
                    $scope.ds_columns.accessions.push(value);
                }
            });

            $scope.siteLinker = {};
            $http.get('/api/sitelinker/accession')
                .success(function(data) {
                    angular.forEach(data, function(value) {
                        $scope.siteLinker[value.name] = value;
                    });
                });
        });
    });

    $scope.$watch('page', function () {
        $scope.pageDirty = !angular.equals($scope.page, $scope.pageOriginal);
    }, true);


    PageColumn.query({}, {page_id: $scope.pageId}, function (columns) {
        $scope.pageColumnsOriginal = angular.copy(columns);
        $scope.pageColumns = columns;
        $scope.pageColumnsLoaded = 1;
    });
    $scope.$watch('pageColumns', function () {
        $scope.pageDirty = !angular.equals($scope.pageColumns, $scope.pageColumnsOriginal);
    }, true);


    // Methods
    $scope.updatePage = function() {
        if (!$scope.pageDirty) {
            return;
        }

        Page.update({
            id:         $scope.pageId,
            title:      $scope.page.title,
            preamble:   $scope.page.preamble,
            postamble:  $scope.page.postamble,
            dataset_id: $scope.page.dataset_id,
            permission: $scope.page.permission
        });

        angular.forEach($scope.pageColumns, function (value, key) {
            PageColumn.update({
                page_id:  value.page_id,
                id:       value.id,
                title:    value.title,
                widgets:  value.widgets,
                sort:     key+1
            });
        } );

        $scope.pageDirty = 0;
        $scope.pageOriginal = angular.copy($scope.page);
        $scope.pageColumnsOriginal = angular.copy($scope.pageColumns);
    };

    $scope.addColumn = function() {
        var newColumn = {
            title: $scope.newColumnName,
            template: '',
            page_id: $scope.pageId
        };

        PageColumn.saveAndFetch(newColumn, function(fullCol) {
            $scope.pageColumns.push(fullCol);
            $scope.currentColumn = fullCol;
        } );
    };

    $scope.removeColumn = function() {
        if (!$scope.deleteColumn) {
            return;
        }

        var confirmed = window.confirm("Are you sure you want to delete this column?");
        if (confirmed) {
            PageColumn.delete(
                {}, {page_id: $scope.pageId, id: $scope.deleteColumn.id},
                function() {
                    if (angular.equals($scope.currentColumn, $scope.deleteColumn)) {
                        $scope.currentColumn = null;
                    }

                    angular.forEach($scope.pageColumns, function (value, key) {
                        if ( angular.equals(value, $scope.deleteColumn) ) {
                            $scope.pageColumns.splice(key, 1);
                        }
                    } );
                }
            );
        }

        return;
    };

    $scope.firstColumn = function() {
        return $scope.pageColumns && angular.equals($scope.currentColumn, $scope.pageColumns[0]);
    };

    $scope.lastColumn = function() {
        return $scope.pageColumns && angular.equals(
            $scope.currentColumn,
            $scope.pageColumns[ $scope.pageColumns.length - 1 ]
        );
    };

    $scope.currentIdx = function() {
        var idx;
        for (idx=0; idx<$scope.pageColumns.length; idx++) {
            if (angular.equals($scope.currentColumn, $scope.pageColumns[idx])) {
                break;
            }
        }
        return idx;
    };

    $scope.columnLeft = function() {
        if ($scope.firstColumn()) {
            return;
        }

        var currentIdx = $scope.currentIdx();
        $scope.pageColumns[currentIdx] = $scope.pageColumns.splice(
            currentIdx-1, 1, $scope.pageColumns[currentIdx]
        )[0];
    };

    $scope.columnRight = function() {
        if ($scope.lastColumn()) {
            return;
        }

        var currentIdx = $scope.currentIdx();
        $scope.pageColumns[currentIdx] = $scope.pageColumns.splice(
            currentIdx+1, 1, $scope.pageColumns[currentIdx]
        )[0];
    };


    $scope.isBold   = curryFormatTest('bold');
    $scope.isItalic = curryFormatTest('italic');
    function curryFormatTest(format) {
        return function(widget) {
            return widget && widget.formatting && widget.formatting.some(function(e) { return e === format; });
        };
    }

    $scope.columnIsActive = function(column) { return $scope.editmode && angular.equals(column, $scope.currentColumn); };
    $scope.columnIsDelete = function(column) { return $scope.editmode && angular.equals(column, $scope.deleteColumn);  };

    $scope.$watch('currentColumn.widgets', function() {
        if (!$scope.currentColumn) {
            return;
        }
        $http.post('/api/template', {widgets: $scope.currentColumn.widgets})
            .success(function(data) {
                $scope.currentColumn.template = data.template;
            })
            .error(function() {
                $scope.alertError('Unable to translate template!');
            });
    }, true);


    $scope.alerts = [];
    $scope.alertSuccess = curryAlert('success');
    $scope.alertError   = curryAlert('error');
    $scope.alertWarning = curryAlert('warning');
    $scope.alertInfo    = curryAlert('info');
    function curryAlert(type) {
        return function(msg) { $scope.alerts.push({type: type, msg: msg}); };
    }
    $scope.closeAlert = function(index) {
        $scope.alerts.splice(index, 1);
    };


    $scope.getServerData = function ( sSource, aoData, fnCallback ) {
        $.ajax( {
            "dataType": "json",
            "type": "GET",
            "url": sSource,
            "data": aoData,
            "success": [
                function(data) {
                    var templates = [];
                    angular.forEach($scope.pageColumns, function (value, key) {
                        templates.push( Handlebars.compile(value.template) );
                    } );

                    var new_data = [];
                    for (var i = 0; i < data.tmplData.length; i++) {
                        new_data[i] = [];
                        for (var j = 0; j < templates.length; j++) {
                            new_data[i][j] = templates[j](data.tmplData[i]);
                        }
                    }
                    data.aaData = new_data;
                },
                fnCallback
            ]
        } );
    };

}]);


judoonCtrl.controller(
    'DatasetColumnCtrl',
    ['$scope', '$routeParams', 'Dataset', 'DatasetColumn',
     'Transform', '$window',
     function ($scope, $routeParams, Dataset, DatasetColumn, Transform, $window) {

    $scope.userName  = $routeParams.userName;
    $scope.datasetId = $routeParams.datasetId;
    DatasetColumn.query({},{dataset_id: $scope.datasetId}, function (columns) {
        $scope.dsColumnsOriginal = angular.copy(columns);
        $scope.dsColumns = columns;
    });

    Transform.query({}, function(transformTypes) {
        $scope.transformTypes = transformTypes;
        $scope.transformTypes.unshift({
            name: 'Join Table',
            id:   'join',
            transforms: [
                {
                    name:    'JoinTable',
                    id:      'join',
                    accepts: 'any',
                    module:  'Accession::JoinTable'
                }

            ],
            constraint: function() { return 1; }
        });
    });

    $scope.$watch('transformType', function() {
        if (
            (!$scope.transformType) ||
            ($scope.transformType.id === 'join') ||
            ($scope.transformType.transforms)
        ) {
            return;
        }

        Transform.query({}, {id: $scope.transformType.id}, function(transforms) {
            $scope.transformType.transforms = transforms;
        });
    });

    Dataset.query({}, function (datasets) {
        var self_idx;
        angular.forEach(datasets, function(value, key) {
            if (value.id === $scope.dataset.id) {
                self_idx = key;
            }
        });
        datasets.splice(self_idx, 1);

        $scope.myDatasets = datasets;
        angular.forEach(datasets, function(value, key) {
            DatasetColumn.query({}, {dataset_id: value.id}, function (columns) {
                value.columns = columns;
            });
        });
    });

    $scope.submitNewColumn = function() {
        var data;

        if ($scope.transform.id === 'join') {
            data = {
                name:         $scope.newColumnName,
                module:       $scope.transform.module,
                dataset_id:   $scope.datasetId,
                input_field:  $scope.sourceColumn.shortname,
                join_dataset: $scope.joinDataset.id,
                join_column:  $scope.joinColumn.shortname,
                to_column:    $scope.outputColumn.shortname
            };
        }
        else {
            data = {
                name:          $scope.newColumnName,
                module:        $scope.transform.module,
                dataset_id:    $scope.datasetId,
                input_field:   $scope.sourceColumn.shortname,
                input_format:  $scope.inputType,
                output_format: $scope.outputType
            };
        }

        DatasetColumn.save({}, data);
        $window.location.reload();
    };

    $scope.$watch('transform', function() {
        $scope.filteredColumns = [];

        if (!$scope.transformType) {
            return;
        }

        angular.forEach($scope.dsColumns, function(value, key) {
            var accepts = $scope.transform.accepts;

            if ((accepts === 'text') && (value.data_type !== 'text')) {
                return;
            }
            if ((accepts === 'accession') && (!value.accession_type)) {
                return;
            }

            $scope.filteredColumns.push(value);
        });
    });

}]);


judoonCtrl.controller(
    'PageColumnTemplateCtrl',
    ['$scope', '$modal', function ($scope, $modal) {

        $scope.$watch('currentColumn', function() {
            if (!$scope.currentColumn) {
                return;
            }
            $scope.cursorWidget = $scope.currentColumn.widgets[ $scope.currentColumn.widgets.length - 1];
        });

        /*
         The cursor is positioned after $scope.cursorWidget in the
         list of widgets. In order to position the cursor at the
         beginning of the list, the column widgets are indexed using a
         one-based indexing.  Index 0 is the beginning of the
         list. Index 1 is the first widget in the list.
         */
        $scope.getCursorIndex = function() {
            return !($scope.cursorWidget && $scope.currentColumn.widgets.length) ? 0
                 : $scope.$parent.currentColumn.widgets.indexOf( $scope.cursorWidget ) + 1;
        };

        $scope.cursorBack = function() {
            var cursorIdx = $scope.getCursorIndex();
            $scope.cursorWidget = cursorIdx < 2 ? null
                                : $scope.currentColumn.widgets[cursorIdx-2];
            return;
        };

        $scope.cursorForward = function() {
            var widgetCount = $scope.currentColumn.widgets.length;
            if (!widgetCount) {
                return;
            }

            var cursorIdx = $scope.getCursorIndex();
            if (cursorIdx < widgetCount) {
                $scope.cursorWidget = $scope.currentColumn.widgets[cursorIdx];
            }

            return;
        };

        function addNode(node) {
            var index = $scope.getCursorIndex();
            $scope.currentColumn.widgets.splice(index, 0, node);
            $scope.cursorWidget = $scope.currentColumn.widgets[index];
            return;
        }
        $scope.addTextNode = function() {
            addNode({type: 'text', value: '', formatting: []});
        };

        $scope.addDataNode = function() {
            addNode({type: 'variable', name: '', formatting: []});
        };

        $scope.addNewlineNode = function() {
            addNode({type: 'newline'});
        };

        $scope.addLinkNode = function() {
            addNode({
                type: 'link',
                formatting: [],
                url: {
                    type:              "varstring",
                    varstring_type:    "variable",
                    accession:         "",
                    text_segments:     [],
                    variable_segments: [],
                    formatting:        []
                },
                label: {
                    type:              "varstring",
                    varstring_type:    "static",
                    accession:         "",
                    text_segments:     [],
                    variable_segments: [],
                    formatting:        []
                }
            });
        };

        $scope.addImageNode = function() {
            addNode({
                type: 'image',
                url: {
                    type:              "varstring",
                    varstring_type:    "variable",
                    accession:         "",
                    text_segments:     [],
                    variable_segments: [],
                    formatting:        []
                }
            });
        };

        $scope.removeNodeAtCursor = function() {
            var index = $scope.getCursorIndex();
            if (!index) {
                return;
            }

            $scope.cursorBack();
            $scope.currentColumn.widgets.splice(index-1, 1);
            return;
        };

        $scope.removeNode = function(widget) {
            var index = $scope.currentColumn.widgets.indexOf(widget);
            $scope.currentColumn.widgets.splice(index, 1);
            return;
        };

        /* Modals */
        $scope.openElementGuide  = function() {
            $modal.open({
                templateUrl: 'elementGuide.html',
                controller: 'ElementGuideCtrl'
            });
        };

        $scope.previewUrl = function(widget) {
            return zipSegments(widget.url);
        };

        $scope.previewLabel = function(widget) {
            return zipSegments(widget.label);
        };

        function zipSegments(varstring) {
            var maxlen = Math.max(
                varstring.text_segments.length,
                varstring.variable_segments.length
            );

            var retstring = '';
            for (var i = 0; i < maxlen; i++) {
                retstring += varstring.text_segments[i] || '';
                retstring += getSampleData(varstring.variable_segments[i]);
            }
            return retstring;
        }

        function getSampleData(colname) {
            return $scope.ds_columns.dict[colname].sample_data[0] || '';
        }
    }]
);

judoonCtrl.controller(
    'ElementGuideCtrl',
    ['$scope', '$modalInstance', function ($scope, $modalInstance) {
        $scope.closeElementGuide = function() { $modalInstance.dismiss(); };
    }]
);

judoonCtrl.controller(
    'LinkBuilderCtrl',
    ['$scope', '$modalInstance', 'currentLink', 'columns', 'siteLinker',
     function ($scope, $modalInstance, currentLink, columns, siteLinker) {

         $scope.columns = columns;
         $scope.url = {
             active: {
                 'acc':    currentLink.url.varstring_type === 'accession' ? true : false,
                 'var':    currentLink.url.varstring_type === 'variable'  ? true : false,
                 'static': currentLink.url.varstring_type === 'static'    ? true : false
             },
             accession: {
                 site:   currentLink.url.accession,
                 source: currentLink.url.variable_segments[0] || ''
             },
             variable: {
                 prefix:   currentLink.url.text_segments[0]     || '',
                 variable: currentLink.url.variable_segments[0] || '',
                 suffix:   currentLink.url.text_segments[1]     || ''
             },
             'static': currentLink.url.varstring_type === 'static' ? currentLink.url.text_segments[0] : ''
         };
         
         $scope.label = {
             type:     currentLink.label.varstring_type,
             'static': currentLink.label.text_segments[0] || '',
             variable: {
                 prefix:   currentLink.label.text_segments[0] || '',
                 variable: currentLink.label.variable_segments[0] || '',
                 suffix:   currentLink.label.text_segments[1] || ''
             }
         };


         $scope.$watch('url.accession.source', function() {
             $scope.linkSites = getLinkableSites(
                 getDataType($scope.url.accession.source)
             );
         }, true);


         $scope.labelPreview = '';
         function updateLabelPreview() {
             switch ($scope.label.type) {
             case 'default':
                 $scope.labelPreview = 'default label';
                 break;
             case 'url':
                 $scope.labelPreview = $scope.urlPreview;
                 break;
             case 'variable':
                 $scope.labelPreview = $scope.label.variable.prefix +
                     getSampleData($scope.label.variable.variable) +
                     $scope.label.variable.suffix;
                 break;
             case 'static':
                 $scope.labelPreview =  $scope.label['static'];
                 break;
             }
         }
         $scope.$watch('label', function() { updateLabelPreview(); }, true);

         $scope.urlPreview = '';
         function updateUrlPreview() {
             if ($scope.url.active['static']) {
                 $scope.urlPreview = $scope.url['static'];
             }
             else if ($scope.url.active.acc) {
                 if (!$scope.url.accession.site) {
                     $scope.urlPreview = '';
                 }
                 else {
                     var accession_parts = getUrlPartsForSite(
                         $scope.url.accession.site,
                         getDataType($scope.url.accession.source)
                     );
                     $scope.urlPreview = accession_parts.prefix +
                         getSampleData($scope.url.accession.source) +
                         accession_parts.suffix;
                 }
             }
             else if ($scope.url.active['var']) {
                 $scope.urlPreview = $scope.url.variable.prefix +
                     getSampleData($scope.url.variable.variable) +
                     $scope.url.variable.suffix;
             }
         }
         $scope.$watch('url', function() {
             updateUrlPreview();
             updateLabelPreview();
         }, true);


         function getSampleData(colname) { return columns.dict[colname].sample_data[0]; }
         function getDataType(colname)   { return columns.dict[colname].data_type; }

         function getLinkableSites(accession) {
             return siteLinker[accession].sites;
         }
         function getUrlPartsForSite(site, accession)  {
             var parts;
             angular.forEach(siteLinker[accession].sites, function(value) {
                 if (value.name === site) {
                     parts = value.mapping;
                 }
             });
             return parts;
         }


         $scope.closeLinkBuilder = function() {
             $modalInstance.dismiss('cancel');
             return false;
         };

         $scope.saveWidget = function() {

             var url;
             if ($scope.url.active['static']) {
                 url = {
                     accession:         '',
                     text_segments:     [$scope.url['static']],
                     variable_segments: [],
                     varstring_type:    'static'
                 };
             }
             else if ($scope.url.active['var']) {
                 url = {
                     accession:         '',
                     text_segments:     [$scope.url.variable.prefix, $scope.url.variable.suffix],
                     variable_segments: [$scope.url.variable.variable],
                     varstring_type:    'variable'
                 };
             }
             else if ($scope.url.active.acc) {
                 var urlParts = getUrlPartsForSite($scope.url.accession.site, getDataType($scope.url.accession.source));
                 url = {
                     accession:         $scope.url.accession.accession,
                     text_segments:     [urlParts.prefix, urlParts.suffix],
                     variable_segments: [$scope.url.accession.source],
                     varstring_type:    'accession'
                 };
             }

             var label;
             if ($scope.label.type === 'default') {
                 label = {
                     text_segments:     [],
                     variable_segments: [],
                     varstring_type:    ''
                 };
             }
             else if ($scope.label.type === 'static') {
                 label = {
                     text_segments:     [$scope.label['static']],
                     variable_segments: [],
                     varstring_type:    'static'
                 };
             }
             else if ($scope.label.type === 'url') {
                 label = angular.copy(url);
                 label.varstring_type = label.variable_segments.length ? 'variable' : 'static';
             }
             else if ($scope.label.type === 'variable') {
                 label = {
                     text_segments:     [$scope.label.variable.prefix, $scope.label.variable.suffix],
                     variable_segments: [$scope.label.variable.variable],
                     varstring_type:    'variable'
                 };
             }
             label.accession = '';

             $modalInstance.close({url: url, label: label});
             return false;
         };
    }]
);


judoonCtrl.controller(
    'ImageBuilderCtrl',
    ['$scope', '$modalInstance', 'currentImage', 'columns',
     function ($scope, $modalInstance, currentImage, columns) {

         $scope.columns = columns;
         $scope.url = {
             type: currentImage.url === 'static' ? 'fixed' : 'fromdata'
         };
         if ($scope.url.type === 'fixed') {
             $scope.url.fixed = currentImage.url.text_segments[0];
         }
         else {
             $scope.url.fromdata = {
                 prefix:     currentImage.url.text_segments[0] || '',
                 datasource: currentImage.url.variable_segments[0] || '',
                 suffix:     currentImage.url.text_segments[1] || ''
             };
         }

         function updateSampleUrl() {
             if ($scope.url.type === 'fixed') {
                 $scope.sampleUrl = $scope.url.fixed;
             }
             else if ($scope.url.type === 'fromdata') {
                 if (!$scope.url.fromdata.datasource) {
                     $scope.sampleUrl = '';
                 }
                 else {
                     $scope.sampleUrl = $scope.url.fromdata.prefix +
                         columns.dict[$scope.url.fromdata.datasource].sample_data[0] +
                         $scope.url.fromdata.suffix;
                 }
             }
         }
         $scope.$watch('url', function() { updateSampleUrl(); }, true);

         $scope.closeImageBuilder = function() {
             $modalInstance.dismiss('cancel');
             return false;
         };

         $scope.saveWidget = function() {
             var url;
             if ($scope.url.type === 'fixed') {
                 url = {
                     accession:         '',
                     text_segments:     [$scope.url.fixed],
                     variable_segments: [],
                     varstring_type:    'static'
                 };
             }
             else if ($scope.url.type === 'fromdata') {
                 url = {
                     accession:         '',
                     text_segments:     [$scope.url.fromdata.prefix, $scope.url.fromdata.suffix],
                     variable_segments: [$scope.url.fromdata.datasource],
                     varstring_type:    'variable'
                 };
             }

             $modalInstance.close({url: url});
             return false;
         };
     }]
);
