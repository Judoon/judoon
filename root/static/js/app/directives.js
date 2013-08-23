'use strict';

var judoonDir = angular.module('judoon.directives', []);


/**  Judoon Data Table

 This directive binds our data api to a jQuery DataTables datatable.

**/

judoonDir.directive('judoonDataTable', ['$timeout', function($timeout) {
    var dataTableTemplate = '<table class="table table-striped table-condensed table-bordered">'
        + '<thead>'
        + '<th ng-repeat="column in columns">{{ column[headerKey] }}</th>'
        + '</thead>'
        + '<tbody></tbody>'
        + '</table>';


    return {
        restrict: 'E',
        replace: true,
        template: dataTableTemplate,
        scope: {
            datasetId     : '=jdtDatasetId',
            columns       : '=jdtColumns',
            headerKey     : '@jdtHeaderKey',
            dataFetchFn   : '=jdtFetchFn'
        },
        link: function(scope, element, attrs) {

            var dataTable;
            var defaultOptions = {
                "bAutoWidth"      : false,
                "bServerSide"     : true,
                "bProcessing"     : true,
                "sPaginationType" : "bootstrap",
                "bDeferRender"    : true,
                "fnServerData"    : scope.dataFetchFn
            };

            function rebuildTable() {
                if (dataTable) {
                    dataTable.fnDestroy();
                }

                var tableOptions = angular.copy(defaultOptions);
                tableOptions["aoColumns"] = [];
                angular.forEach(scope.columns, function (value, key) {
                    tableOptions["aoColumns"][key] = value[scope.headerKey];
                } );

                dataTable = element.dataTable(tableOptions);
            }

            // datasetId may not be available at link time
            var unbindDsIdWatch = scope.$watch('datasetId', function() {
                if (!scope.datasetId) {
                    return;
                }

                // this won't change over life of the directive
                defaultOptions["sAjaxSource"] = "/api/datasetdata/" + scope.datasetId;

                // just in case this fired after the columns watch
                if (scope.columns && scope.columns.length) {
                    $timeout(function() { rebuildTable(); }, 0, false);
                }

                unbindDsIdWatch();
            });

            // columns may not be available at link time
            scope.$watch('columns', function() {
                if (!scope.datasetId || !scope.columns || !scope.columns.length) {
                    return; // too soon.
                }

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
                        { name: 'groups',    items: ["NumberedList", "BulletedList", "DefinitionList", "Outdent", "Indent", "Blockquote"] },
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


judoonDir.directive(
    'judoonWidgetFactory',
    ['$compile', function($compile) {
        return {
            restrict: 'E',
            replace: true,
            template: '<div class="widget-object widget-inline input-append dropdown"></div>',
            link: function(scope, element, attrs) {
                element.append('<judoon-'+scope.widget.type+'-widget widget="widget">');
                if (scope.widget.type !== 'newline') {
                    element.append('<judoon-formatting-widget>');
                }
                $compile(element.contents())(scope);
            }
        };
    }]
);

judoonDir.directive(
    'judoonTextWidget',
    [function() {
        return {
            restrict: 'E',
            replace: false,
            templateUrl: '/static/html/partials/widget-text.html'
        };
    }]
);

judoonDir.directive(
    'judoonVariableWidget',
    [function() {
        return {
            restrict: 'E',
            replace: false,
            templateUrl: '/static/html/partials/widget-variable.html'
        };
    }]
);

judoonDir.directive(
    'judoonNewlineWidget',
    [function() {
        return {
            restrict: 'E',
            replace: false,
            templateUrl: '/static/html/partials/widget-newline.html'
        };
    }]
);

judoonDir.directive(
    'judoonLinkWidget',
    [function() {
        return {
            restrict: 'E',
            replace: false,
            templateUrl: '/static/html/partials/widget-link.html'
        };
    }]
);

judoonDir.directive(
    'judoonFormattingWidget',
    [function() {
        return {
            restrict: 'E',
            replace: false,
            templateUrl: '/static/html/partials/widget-formatting.html'
        };
    }]
);
