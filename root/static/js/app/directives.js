/*jshint globalstrict: true */
/*global angular */

'use strict';

var judoonDir = angular.module('judoon.directives', []);


/**  Judoon Data Table

 This directive binds our data api to a jQuery DataTables datatable.

**/

judoonDir.directive('judoonDataTable', ['$timeout', function($timeout) {
    return {
        restrict    : 'E',
        replace     : true,
        templateUrl : '/static/html/partials/judoon-data-table.html',
        transclude  : false,
        scope       : {
            colDefs   : '=jdtColDefs',
            dataUrl   : '=jdtDataUrl',
            editCol   : '=jdtEditCol',
            deleteCol : '=jdtDeleteCol'
        },
        link: function(scope, element, attrs) {

            var dt, defaultOptions = {
                "bAutoWidth"      : false,
                "bServerSide"     : true,
                "bProcessing"     : true,
                "sPaginationType" : "bootstrap",
                "bDeferRender"    : true,
                "sAjaxSource"     : scope.dataUrl,
                "sAjaxDataProp"   : "tmplData"
            };

            function rebuildTable(nbrColumnsChanged) {
                if (dt) {
                    dt.fnDestroy();
                    if (nbrColumnsChanged) {
                        dt.find('tr').remove();
                    }
                }

                var tableOptions = angular.copy(defaultOptions);
                tableOptions.aoColumns = scope.colDefs;
                dt = element.dataTable(tableOptions);
                if (nbrColumnsChanged) {
                    updateHighlights(scope.editCol, 'active_col');
                    updateHighlights(scope.deleteCol, 'danger_col');
                }
            }


            function updateHighlights(column, highlightClass) {
                element.find('th').removeClass(highlightClass);
                if (column) {
                    var idx;
                    angular.forEach(scope.colDefs, function(value, key) {
                        if (value.column.id === column.id) {
                            idx = key;
                        }
                    });
                    angular.element(element.find('th')[idx]).addClass(highlightClass);
                }
            }

            scope.$watch('editCol', function() {
                updateHighlights(scope.editCol, 'active_col');
            });

            scope.$watch('deleteCol', function() {
                updateHighlights(scope.deleteCol, 'danger_col');
            });


            // columns may not be available at link time
            scope.$watch('colDefs', function(oldval, newval) {
                if (!scope.colDefs || !scope.colDefs.length) {
                    return; // too soon.
                }
                var nbrColumnsChanged = oldval.length !== newval.length;
                $timeout(
                    function() {rebuildTable(nbrColumnsChanged);}, 0, false
                );
            }, true);
        }
    };
}]);


judoonDir.directive(
    'judoonFileInput',
    ['$timeout', function($timeout) {
        return {
            restrict    : 'E',
            replace     : true,
            templateUrl : '/static/html/partials/judoon-file-input.html',
            scope       : { inputName : '@' },
            link        : function(scope, elem, attrs) {
                elem.find('input[type="file"]').attr('name', attrs.inputName);
                elem.find('.fake-uploader').click(function() {
                    elem.find('input[type="file"]').click();
                });
            },
            controller: ['$scope', function ($scope) {
                $scope.setFile = function (elem) {
                    $scope.filePath = elem.files[0].name;
                    $scope.$apply();
                };
            }]
        };
    }]
);

judoonDir.directive(
    'judoonWidgetFactory',
    ['$compile', function($compile) {
        return {
            restrict: 'E',
            replace: true,
            template: '<div class="widget-object input-append dropdown"></div>',
            link: function(scope, element, attrs) {
                element.append('<judoon-'+scope.widget.type+'-widget widget="widget">');
                if (scope.widget.type !== 'newline' && scope.widget.type !== 'image') {
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
    ['$modal', function($modal) {
        function link(scope, elem, attrs) {

            function openLinkBuilder(widget) {
                var modalInstance = $modal.open({
                    resolve: {
                        currentLink: function() {
                            return {
                                url:   angular.copy(widget.url),
                                label: angular.copy(widget.label)
                            };
                        },
                        columns: function() {
                            return {
                                all:        scope.dataset.columns,
                                accessions: scope.ds_columns.accessions,
                                dict:       scope.ds_columns.dict
                            };
                        },
                        siteLinker: function() { return scope.siteLinker; }
                    },
                    templateUrl:  '/static/html/partials/widget-link-builder.html',
                    controller: 'LinkBuilderCtrl'
                });

                modalInstance.result.then(
                    function (linkProps) {
                        widget.url   = linkProps.url;
                        widget.label = linkProps.label;
                    }
                );
            }

            angular.element(elem.find('input')).on(
                'click', function () {
                    openLinkBuilder(scope.widget);
                    scope.$apply();
                }
            );
        }

        return {
            restrict: 'E',
            replace: false,
            templateUrl: '/static/html/partials/widget-link.html',
            link: link
        };
    }]
);

judoonDir.directive(
    'judoonImageWidget',
    ['$modal', function($modal) {
        function link(scope, elem, attrs) {

            function openImageBuilder(widget) {
                var modalInstance = $modal.open({
                    resolve: {
                        currentImage: function() {
                            return {
                                url:   angular.copy(widget.url),
                            };
                        },
                        columns: function() {
                            return {
                                all:  scope.dataset.columns,
                                dict: scope.ds_columns.dict
                            };
                        }
                    },
                    templateUrl:  '/static/html/partials/widget-image-builder.html',
                    controller: 'ImageBuilderCtrl'
                });

                modalInstance.result.then(
                    function (imageProps) {
                        widget.url   = imageProps.url;
                    }
                );
            }

            angular.element(elem.find('input')).on(
                'click', function () {
                    openImageBuilder(scope.widget);
                    scope.$apply();
                }
            );
        }

        return {
            restrict: 'E',
            replace: false,
            templateUrl: '/static/html/partials/widget-image.html',
            link: link
        };
    }]
);



judoonDir.directive(
    'judoonFormattingWidget',
    [function() {

        function link(scope, elem, attrs) {

            function toggleFormatting(format) {
                var idx = scope.widget.formatting.indexOf(format);
                if (idx === -1) {
                    scope.widget.formatting.push(format);
                }
                else {
                    scope.widget.formatting.splice(idx, 1);
                }
                return;
            }
            function toggleFormattingBold()   { toggleFormatting('bold');   }
            function toggleFormattingItalic() { toggleFormatting('italic'); }

            function deleteWidget() {
                scope.$parent.removeNode(scope.widget);
            }

            var actions = elem.find('ul').find('a');
            angular.element(actions[0]).on('click', function() { toggleFormattingBold();   scope.$apply(); });
            angular.element(actions[1]).on('click', function() { toggleFormattingItalic(); scope.$apply(); });
            angular.element(actions[2]).on('click', function() { deleteWidget();           scope.$apply(); });
        }

        return {
            restrict: 'E',
            replace: false,
            templateUrl: '/static/html/partials/widget-formatting.html',
            link: link
        };
    }]
);


judoonDir.directive(
    'judoonLinkBuilderWidget',
    [function() {
        return {
            restrict: 'E',
            replace: false,
            templateUrl: '/static/html/partials/widget-link-builder.html'
        };
    }]
);
