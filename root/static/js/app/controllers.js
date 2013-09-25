/*jshint globalstrict: true */
/*jshint jquery: true */
/*global angular, Handlebars, window */

'use strict';

var judoonCtrl = angular.module('judoon.controllers', []);

judoonCtrl.controller(
    'DatasetCtrl',
    ['$scope', '$routeParams', '$http', 'Dataset', 'DatasetColumn',
     'Page', 'DatasetPage', 'DataType',
     function ($scope, $routeParams, $http, Dataset, DatasetColumn,
               Page, DatasetPage, DataType) {


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

             DatasetColumn.query({}, {dataset_id: $scope.datasetId}, function (columns) {
                 $scope.dataset.columns = columns;
                 $scope.dsColumnsLoaded = 1;
                 $scope.dsColumnsOriginal = angular.copy(columns);
             });

             DatasetPage.query({}, {dataset_id: $scope.datasetId}, function (pages) {
                 $scope.dataset.pages = pages;
             });
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
    'DatasetColumnCtrl',
    ['$scope', '$routeParams', 'Dataset', 'DatasetColumn', 'Lookup', '$window',
     function ($scope, $routeParams, Dataset, DatasetColumn, Lookup, $window) {

         Lookup.query({}, function (lookups) {
             var self_idx;
             angular.forEach(lookups, function (value, key) {
                 if ((value.group_id === 'internal') && (value.id+"" === $scope.datasetId)) {
                     self_idx = key;
                 }
             });

             lookups.splice(self_idx,1);
             $scope.lookups = lookups;
         });

         $scope.$watch('currentLookup', function vivfyInputs() {
             $scope.thatJoinColumn = null;
             if (!$scope.currentLookup) {
                 return;
             }

             if (!$scope.currentLookup.inputColumnsCanon) {
                 $scope.currentLookup.inputColumnsCanon = Lookup.query({}, {
                     group_id: $scope.currentLookup.group_id,
                     id:       $scope.currentLookup.id,
                     io:       'input'
                 });
             }
         });

         $scope.$watch('currentLookup.inputColumnsCanon', function () { filterInputColumns(); }, true);

         $scope.$watch('thatJoinColumn', function vivifyOutputs() {
             $scope.thatSelectColumn = null;
             if (!$scope.thatJoinColumn) {
                 return;
             }

             if (!$scope.thatJoinColumn.outputColumns) {
                 $scope.thatJoinColumn.outputColumns = Lookup.query({}, {
                     group_id: $scope.currentLookup.group_id,
                     id:       $scope.currentLookup.id,
                     io:       'input',
                     input_id: $scope.thatJoinColumn.id,
                     sub_io:   'output'
                 });
             }
         });


         $scope.restrictByType = false;
         $scope.$watch('restrictByType', function () { filterInputColumns(); });
         function filterInputColumns() {
             if (!$scope.currentLookup) {
                 return;
             }

             $scope.currentLookup.inputColumns = [];

             if ($scope.restrictByType) {
                 if (!$scope.thisJoinColumn) {
                     return;
                 }
                 angular.forEach($scope.currentLookup.inputColumnsCanon, function(value) {
                     if (value.type === $scope.thisJoinColumn.data_type) {
                         $scope.currentLookup.inputColumns.push(
                             angular.copy(value)
                         );
                     }
                 });
             }
             else {
                 $scope.currentLookup.inputColumns = angular.copy(
                     $scope.currentLookup.inputColumnsCanon
                 );
             }
         }


         $scope.submitNewColumn = function() {
             var data = {
                 dataset_id:        $scope.datasetId,
                 new_col_name:      $scope.newColumnName,
                 this_table_id:     $scope.datasetId,
                 that_table_id:     $scope.currentLookup.full_id,
                 this_joincol_id:   $scope.thisJoinColumn.shortname,
                 that_joincol_id:   $scope.thatJoinColumn.id,
                 that_selectcol_id: $scope.thatSelectColumn.id
             };

             DatasetColumn.save(
                 {}, data,
                 function() {
                     $scope.addAlert('success', 'Column added!');
                     $window.location.reload();
                 },
                 function() { $scope.addAlert('error', 'Something went wrong!'); }
             );
         };

     }
    ]
);



judoonCtrl.controller(
    'PageCtrl',
    ['$scope', '$routeParams', '$http',
     'Page', 'PageColumn', 'Dataset', 'DatasetColumn',
     function ($scope, $routeParams, $http, Page, PageColumn, Dataset,
               DatasetColumn) {

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
                 accession : currentLink.url.varstring_type === 'accession' ? true : false,
                 fromdata  : currentLink.url.varstring_type === 'variable'  ? true : false,
                 fixed     : currentLink.url.varstring_type === 'static'    ? true : false
             },
             accession: { site: '', source: ''},
             fromdata:  { prefix: '', variable: '', suffix: ''},
             fixed:     ''
         };
         if ($scope.url.active.accession) {
             $scope.url.accession.site   = currentLink.url.accession;
             $scope.url.accession.source = currentLink.url.variable_segments[0];
         }
         else if ($scope.url.active.fromdata) {
             $scope.url.fromdata.prefix   = currentLink.url.text_segments[0];
             $scope.url.fromdata.variable = currentLink.url.variable_segments[0];
             $scope.url.fromdata.suffix   = currentLink.url.text_segments[1];
         }
         else {
             $scope.url.fixed = currentLink.url.text_segments[0];
         }


         $scope.label = {
             type     : currentLink.label.varstring_type,
             fixed    : '',
             fromdata : { prefix: '', variable: '', suffix: ''}
         };
         if ($scope.label.type === 'static') {
             $scope.label.fixed = currentLink.label.text_segments[0] || getLabelDefault();
         }
         else {
             $scope.label.fromdata.prefix   = currentLink.label.text_segments[0];
             $scope.label.fromdata.variable = currentLink.label.variable_segments[0];
             $scope.label.fromdata.suffix   = currentLink.label.text_segments[1];
         }

         function getLabelDefault() {
             return $scope.url.active.accession && $scope.url.accession.site ?
                 getCurrentSite().label : 'Link';
         }


         $scope.$watch('url.accession.source', function() {
             $scope.linkSites = getLinkableSites();
         }, true);


         $scope.labelPreview = '';
         function updateLabelPreview() {
             switch ($scope.label.type) {
             case 'default':
                 $scope.labelPreview = getLabelDefault();
                 break;
             case 'url':
                 $scope.labelPreview = $scope.urlPreview;
                 break;
             case 'variable':
                 $scope.labelPreview = $scope.label.fromdata.prefix +
                     getSampleData($scope.label.fromdata.variable) +
                     $scope.label.fromdata.suffix;
                 break;
             case 'static':
                 $scope.labelPreview =  $scope.label.fixed;
                 break;
             }
         }
         $scope.$watch('label', function() { updateLabelPreview(); }, true);

         $scope.urlPreview = '';
         function updateUrlPreview() {
             if ($scope.url.active.fixed) {
                 $scope.urlPreview = $scope.url.fixed;
             }
             else if ($scope.url.active.accession) {
                 if (!$scope.url.accession.site) {
                     $scope.urlPreview = '';
                 }
                 else {
                     var accession_parts = getUrlPartsForCurrentSite();
                     $scope.urlPreview = accession_parts.prefix +
                         getSampleData($scope.url.accession.source) +
                         accession_parts.suffix;
                 }
             }
             else if ($scope.url.active.fromdata) {
                 $scope.urlPreview = $scope.url.fromdata.prefix +
                     getSampleData($scope.url.fromdata.variable) +
                     $scope.url.fromdata.suffix;
             }
         }
         $scope.$watch('url', function() {
             updateUrlPreview();
             updateLabelPreview();
         }, true);


         function getSampleData(colname) { return columns.dict[colname].sample_data[0]; }
         function getDataType(colname)   { return columns.dict[colname].data_type; }


         function getLinkableSites() {
             return siteLinker[getDataType($scope.url.accession.source)].sites;
         }
         function getCurrentSite() {
             var site;
             angular.forEach(getLinkableSites(), function(value) {
                 if (value.name === $scope.url.accession.site) {
                     site = value;
                 }
             });
             return site;
         }
         function getUrlPartsForCurrentSite()  {
             return getCurrentSite().mapping;
         }


         $scope.closeLinkBuilder = function() {
             $modalInstance.dismiss('cancel');
             return false;
         };

         $scope.saveWidget = function() {

             var url;
             if ($scope.url.active.fixed) {
                 url = {
                     accession:         '',
                     text_segments:     [$scope.url.fixed],
                     variable_segments: [],
                     varstring_type:    'static'
                 };
             }
             else if ($scope.url.active.fromdata) {
                 url = {
                     accession:         '',
                     text_segments:     [$scope.url.fromdata.prefix, $scope.url.fromdata.suffix],
                     variable_segments: [$scope.url.fromdata.variable],
                     varstring_type:    'variable'
                 };
             }
             else if ($scope.url.active.accession) {
                 var urlParts = getUrlPartsForCurrentSite();
                 url = {
                     accession:         $scope.url.accession.site,
                     text_segments:     [urlParts.prefix, urlParts.suffix],
                     variable_segments: [$scope.url.accession.source],
                     varstring_type:    'accession'
                 };
             }

             var label;
             if ($scope.label.type === 'default') {
                 label = {
                     text_segments:     [getLabelDefault()],
                     variable_segments: [],
                     varstring_type:    'static'
                 };
             }
             else if ($scope.label.type === 'static') {
                 label = {
                     text_segments:     [$scope.label.fixed],
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
                     text_segments:     [$scope.label.fromdata.prefix, $scope.label.fromdata.suffix],
                     variable_segments: [$scope.label.fromdata.variable],
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
