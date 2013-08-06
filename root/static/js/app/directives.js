'use strict';

var judoonDir = angular.module('judoon.directives', []);

judoonDir.directive('judoonDataTable', ['$timeout', function($timeout) {
    return {
        link: function(scope, element, attrs) {

            var dataTable;
            var defaultOptions = {
                "bAutoWidth"      : false,
                "bServerSide"     : true,
                "bProcessing"     : true,
                "sPaginationType" : "bootstrap",
                "bDeferRender"    : true,
                "fnServerData"    : scope.getServerData
            };

            function rebuildTable() {
                if (dataTable) {
                    dataTable.fnDestroy();
                }

                var tableOptions = angular.copy(defaultOptions);
                tableOptions["aoColumns"] = [];
                angular.forEach(scope.pageColumns, function (value, key) {
                    tableOptions["aoColumns"][key] = value.title;
                } );

                dataTable = element.dataTable(tableOptions);
            }


            var unbindDsIdWatch = scope.$watch('pageLoaded', function() {
                if (!scope.pageLoaded) {
                    return;
                }

                // this won't change over life of the directive
                defaultOptions["sAjaxSource"] = "/api/datasetdata/" + scope.page.dataset_id;
                unbindDsIdWatch();
            });

            scope.$watch('pageColumns', function() {
                if (!scope.pageColumnsLoaded || !scope.pageLoaded) {
                    return; // too soon.
                }

                // run rebuild table after digest
                $timeout(function() { rebuildTable(); }, 0, false);
            }, true);
        }
    };
}]);

judoonDir.directive('judoonDataSmable', ['$timeout', function($timeout) {
    return {
        link: function(scope, element, attrs) {

            var dataTable;
            var defaultOptions = {
                "bAutoWidth"      : false,
                "bServerSide"     : true,
                "bProcessing"     : true,
                "sPaginationType" : "bootstrap",
                "bDeferRender"    : true,
                "fnServerData"    : scope.getServerData
            };

            function rebuildTable() {
                if (dataTable) {
                    dataTable.fnDestroy();
                }

                var tableOptions = angular.copy(defaultOptions);
                tableOptions["aoColumns"] = [];
                angular.forEach(scope.dataset.columns, function (value, key) {
                    tableOptions["aoColumns"][key] = value.title;
                } );

                dataTable = element.dataTable(tableOptions);
            }

            scope.$watch('dataset.columns', function() {
                if (!scope.dsColumnsLoaded) {
                    return; // too soon.
                }

                defaultOptions["sAjaxSource"] = "/api/datasetdata/" + scope.datasetId;

                // run rebuild table after digest
                $timeout(function() { rebuildTable(); }, 0, false);
            }, true);
        }
    };
}]);


judoonDir.directive('judoonCkeditor', [function() {
    return {
        link: function(scope, elm, attr) {
            var ckConfig;
            if (attr.ckEditType === "inline") {
                ckConfig = {
                    toolbar: [
                        { name: 'formatting', items: ["Bold", "Italic", "Underline", "Strike", "Subscript", "Superscript", "RemoveFormat",'-','Undo','Redo'] }
                    ]
                };
            }
            else {
                ckConfig = {
                    toolbar: [
                        { name: 'clipboard', items: ['Cut','Copy','Paste','PasteText','PasteWord','-','Undo','Redo'] },
                        { name: 'editing',   items: ['Find','Replace','-','SelectAll','-','Scayt'] },
                        { name: 'links',     items: ['Link','Unlink','Anchor'] },
                        { name: 'insert',    items: ['Image', 'Table', 'HorizontalRule', 'SpecialChar'] },
                        { name: 'groups',    items: ["NumberedList", "BulletedList", "DefinitionList", "Outdent", "Indent", "Blockquote", ] },
                        '/',
                        { name: 'formatting', items: ["Bold", "Italic", "Underline", "Strike", "Subscript", "Superscript", "RemoveFormat"] },
                        { name: 'paragraph',  items: ["JustifyLeft", "JustifyCenter", "JustifyRight", "JustifyBlock" ] },
                        { name: 'styles',     items: ["Format", "Font", "FontSize", "TextColor", "BGColor" ] },
                        { name: 'about',      items: ["About"] }
                    ],
                    removePlugins: 'smiley,flash,iframe,pagebreak',
                    extraAllowedContent: 'h5 h6 ul ol li dl dd dt'
                };
            }

            scope.$watch('editmode', function() {
                if (scope.editmode == 1) {
                    elm.attr('contenteditable', 'true');
                    var ck = CKEDITOR.inline(elm[0], ckConfig);
                    elm.data('editor', ck);
                }
                else {
                    var ck = elm.data('editor');
                    if (ck) {
                        ck.destroy();
                    }
                    elm.attr('contenteditable', 'false');
                }
            });

        }
    };
}]);


judoonDir.directive('contenteditable', [function() {
    return {
        restrict: 'A', // only activate on element attribute
        require: '?ngModel', // get a hold of NgModelController
        link: function(scope, element, attrs, ngModel) {
            if(!ngModel) return; // do nothing if no ng-model

            // Specify how UI should be updated
            ngModel.$render = function() {
                element.html(ngModel.$viewValue || '');
            };

            // Listen for change events to enable binding
            element.bind('blur keyup change', function() {
                scope.$apply(read);
            });
            read(); // initialize

            // Write data to the model
            function read() {
                ngModel.$setViewValue(element.html());
            }
        }
    };
}]);
